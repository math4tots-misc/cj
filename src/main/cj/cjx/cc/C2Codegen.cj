package cjx.cc

import cj.BigInt
import cjx.cc.C2Code
import cj.DynamicBuffer
import cjx.cc.C2MemDesc
import cjx.parser.Mark
import cj.Error
import cjx.parser.MError
import cj.Uint8Array
import cjx.cc.C2IR
import cjx.binaryen.Binaryen

class C2Codegen {
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto
    private static val stackSize = 4096
    private static val maxMemPageCount = 8192
    private static val wasmPageSize = 65536

    var enableStackTrace = true
    var optimize = false
    private val m: Binaryen.Module = Binaryen.Module()
    private var labelCount = 0
    private var localSlotSP = -1 # index of wasm local variable pointing to start of local stack
    private var cLocalsByteSize = -1 # current number of bytes on the stack
    private var cLocalsMaxbyteSize = -1 # total number of bytes the required on the stack
    private var locals: List[Binaryen.Type] = []
    private var cLocalOffsets: Map[Int, Int] = MapOf()
    private val initData: DynamicBuffer = DynamicBuffer([])
    private val cGlobalOffsets: Map[String, Int] = MapOf()
    private var cGlobalsEnd: Int = stackSize
    private val strlitCache: Map[Uint8Array, Int] = MapOf()
    private val debugNameCache: Map[String, Int] = MapOf()
    private val debugNames: List[String] = []
    private var currentFunc: C2IR.Func? = null
    private var funcGotoTable: Map[String, GotoTarget] = MapOf()
    private var currentBreakLabel: String? = null
    private var currentContinueLabel: String? = null

    ## used for functions with derived return types
    private var retptrLocalIndex: Int? = null

    def emit(self, tu: C2IR.TranslationUnit): C2Code {
        m.addMemoryImport("0", "js", "memory")

        # reserve space for global variables
        for gvar in tu.gvars {
            Assert(gvar.name not in cGlobalOffsets)
            val alignment = gvar.type.alignment()
            cGlobalsEnd = cGlobalsEnd.roundUp(alignment)
            Assert.equal(cGlobalsEnd % alignment, 0)
            cGlobalOffsets[gvar.name] = cGlobalsEnd
            cGlobalsEnd += gvar.type.size()
        }

        # initialize the stack pointer
        m.addGlobal("SP", i32, true, m.i32.const(stackSize))

        if enableStackTrace {
            m.addFunctionImport(
                "__push", "c", "__push", Binaryen.createType([i32, i32, i32]), none)
            m.addFunctionImport("__pop", "c", "__pop", Binaryen.createType([]), none)
        }

        for func in tu.funcs {
            func(func)
        }

        val cStaticDataEnd = cGlobalsEnd + initData.byteLength
        val initMemPageCount = (cStaticDataEnd + wasmPageSize - 1) // wasmPageSize
        m.setMemory(initMemPageCount, maxMemPageCount)

        m.validate()
        if optimize { m.optimize() }
        # IO.println(m.emitText())
        C2Code(
            m.emitBinary(),
            C2MemDesc(
                initMemPageCount,
                maxMemPageCount,
                cGlobalsEnd,        # initialized data offset
                initData.toDataView()),
            debugNames)
    }

    def getCurrentInitDataEnd(self): Int = cGlobalsEnd + initData.size()

    def alignInitData(self, alignment: Int) {
        if getCurrentInitDataEnd() % alignment != 0 {
            val addedByteLen = alignment - (getCurrentInitDataEnd() % alignment)
            for i = 0; i < addedByteLen; i++ { initData.addUint8(0) }
        }
    }

    def newLabel(self): String {
        val name = "l" + labelCount
        labelCount++
        name
    }

    def newLocal(self, type: Binaryen.Type): Int {
        val index = locals.size()
        locals.add(type)
        index
    }

    def withLocal[R](self, type: Binaryen.Type, f: Fn[Int, R]): R {
        val local = newLocal(type)
        f.call(local)
        # while methods like withLocal help to reflect syntactically
        # the idea that temporary variables are scoped, we don't actually
        # do any kind of manual reuse. Instead, we let Binaryen's
        # optimizer figure out the best way to recycle locals.
    }

    ## Store the given expression in a new temporary variable and an expression
    ## assigning to that
    def withLocalSet[R](self, expr: C2IR.Expr, f: Fn[Int, Binaryen.Expression, R]): R {
        val type = type(expr.type)
        val bexpr = expr(expr)
        val local = newLocal(type)
        val assign = m.local.set(local, bexpr)
        f.call(local, assign)
    }

    ## Store the given expression in a new temporary variable and an expression
    ## assigning to that
    def _withLocalSet[R](self, type: C2IR.Type, expr: Binaryen.Expression, f: Fn[Int, Binaryen.Expression, R]): R {
        val local = newLocal(type(type))
        val assign = m.local.set(local, expr)
        f.call(local, assign)
    }

    def type(self, type: C2IR.Type): Binaryen.Type {
        when type {
            case void; case bool; case char; case int; case short = i32
            case long = i64
            case array(..) = i32
            case ptr(..) = i32
            case func(..) = i32
            case derived(..) = i32
        }
    }

    def getLocalOffset(self, var_: C2IR.Var): Int = cLocalOffsets[var_.index]
    def getGlobalOffset(self, gvar: C2IR.GVar): Int = cGlobalOffsets[gvar.name]

    def __get_stackPtr(self): Binaryen.Expression = m.global.get("SP", i32)

    def restoreSP(self): Binaryen.Expression {
        m.global.set("SP", m.local.get(localSlotSP, i32))
    }

    ## Alocate memory on the stack.
    ## Returns the stack offset where the memory was allocated
    def alloca(self, size: Int, alignment: Int): Int {
        cLocalsByteSize = cLocalsByteSize.roundUp(alignment)
        var offset = cLocalsByteSize
        cLocalsByteSize += size
        if cLocalsMaxbyteSize < cLocalsByteSize { cLocalsMaxbyteSize = cLocalsByteSize }
        offset
    }

    def func(self, func: C2IR.Func) {
        val functype = func.type
        val (wasmReturnType, wasmParamTypes) = if functype.returnType.isDerived() {
            (none, functype.paramTypes.map(t -> type(t)) + [i32])
        } else {
            (type(functype.returnType), functype.paramTypes.map(t -> type(t)))
        }
        if not is_set!(func, body) {
            m.addFunctionImport(
                func.name, "c", func.name, Binaryen.createType(wasmParamTypes), wasmReturnType)
            return ()
        }

        # IO.println(func.name + " -> " + func.body)
        # IO.println(func.name + " -> " + wasmReturnType + wasmParamTypes)

        locals = wasmParamTypes.clone()
        retptrLocalIndex = if functype.returnType.isDerived() {
            null(locals.size() - 1) } else { null }
        localSlotSP = newLocal(i32)
        Assert.equal(
            localSlotSP,
            func.params.size() + if functype.returnType.isDerived() { 1 } else { 0 })
        cLocalOffsets = MapOf()
        cLocalsByteSize = 0
        currentFunc = null(func)
        funcGotoTable = MapOf()
        currentBreakLabel = null
        currentContinueLabel = null

        val stmts = [
            # save the stack pointer here so that we can easily restore
            # the stack pointer without knowing the size of the stack frame.
            m.local.set(localSlotSP, m.global.get("SP", i32)),

            # placeholder -- once we have emitted the rest of the function body,
            # we will know the actual stack size this function requires.
            # We reserve a spot here so that we can update it later.
            m.nop(),
        ]
        val params = func.params
        for i = 0; i < params.size(); i++ {
            val param = params[i]
            cLocalOffsets[param.index] = alloca(param.type.size(), param.type.alignment())
            val ptype = type(param.type)
            stmts.add(_dropsetderef(
                param.mark,
                param.type,
                getLocalOffset(param),
                stackPtr,
                m.local.get(i, ptype)))
        }
        stmts.add(stmt(func.body))
        if func.name == "main" or functype.returnType.isVoid() {
            # main function has an implicit "return 0"
            # functions that return void also have an implicit return at the end
            # (we translate void to i32 for convenience, so we still just return 0)
            stmts.add(restoreSP())
            stmts.add(m.return_(m.i32.const(0)))
        } else {
            stmts.add(m.unreachable())
        }

        # at this point, we should know how much space we need to allocate on the
        # stack, so we can patch the nop from the beginning to update the stack
        # pointer.
        cLocalsMaxbyteSize = cLocalsMaxbyteSize.roundUp(8)
        stmts[1] = m.global.set("SP",
                m.i32.sub(m.global.get("SP", i32), m.i32.const(cLocalsMaxbyteSize)))
        val body = m.block(null, stmts, auto)
        val binaryenFunc = m.addFunction(
            func.name,
            Binaryen.createType(wasmParamTypes),
            wasmReturnType,
            locals[wasmParamTypes.size():],
            body)

        if not func.attr.static_ {
            m.addFunctionExport(func.name, func.name)
        }
        currentFunc = null
    }

    def getDebugNameIndex(self, filepath: String): Int {
        if filepath not in debugNameCache {
            val index = debugNames.size()
            Assert.equal(index, debugNameCache.size())
            debugNameCache[filepath] = debugNameCache.size()
            debugNames.add(filepath)
        }
        debugNameCache[filepath]
    }

    def stmtInBlock(self, s: C2IR.Stmt): Binaryen.Expression {
        # Every statement creates its own little scope.
        # The intent is to clear out all temporary variables
        # that might have been allocated by some expressions.
        val savedOffset = cLocalsByteSize
        val ret = stmt(s)
        cLocalsByteSize = savedOffset
        ret
    }

    ## A goto target.
    ## Currently, only 'forward' gotos are supported.
    class GotoTarget {
        ## If you are "behind" the target, branch on this label to land here
        val forwardLabel: String

        ## If you are "ahead of" the target, branch on this label to land here
        ## NOTE: In the current implementation, a backward label is only available
        ## for the first label within each block.
        val backwardLabel: String?

        ## Indicates whether this goto label has been 'passed'.
        ## This is used to determine whether a simple branching to the
        ## forward label will suffice.
        var passed: Bool = false

        ## Indicates wheter this goto label has been 'expired'.
        ## This implies that we have left the block in which this label
        ## was defined. While in standard C, these gotos are permitted,
        ## to keep our implementation simple, we forbid jumping to
        ## any expired labels.
        var expired: Bool = false
    }

    def block(self, block: C2IR.Stmt): Binaryen.Expression {
        val savedStackOffset = cLocalsByteSize
        allocVarsForBlock(block.vars)
        val stmts = stmtsWithLabels(block.stmts)
        cLocalsByteSize = savedStackOffset
        m.block(null, stmts, auto)
    }

    def stmtExpr(self, expr: C2IR.Expr): Binaryen.Expression {
        if expr.type.isDerived() {
            # Supporting this would require allcating space for the
            # resulting derived (i.e. struct or union)
            # It can be done, but given that statement expressions are
            # a non-standard extension and to keep things simple for myself,
            # I'm going to forgo supporting this feature for now.
            throw MError(
                "Returning a struct or union from a block expression is not supported",
                [expr.mark])
        }
        val savedStackOffset = cLocalsByteSize
        allocVarsForBlock(expr.vars)
        val parts = stmtsWithLabels(expr.stmts)
        parts.add(expr(expr.arg))
        cLocalsByteSize = savedStackOffset
        m.block(null, parts, auto)
    }

    def allocVarsForBlock(self, vars: List[C2IR.Var]) {
        for var_ in vars {
            cLocalOffsets[var_.index] = alloca(var_.type.size(), var_.type.alignment())
        }
    }

    def stmtsWithLabels(self, stmts: List[C2IR.Stmt]): List[Binaryen.Expression] {
        var backwardLabel = null[String]
        var startOfBlock = true
        for s in stmts {
            if s.labels {
                val wasmForwardLabel = newLabel()
                val wasmBackwardLabel = if startOfBlock {
                    backwardLabel = null(newLabel())
                    backwardLabel
                } else { null }
                val target = GotoTarget(wasmForwardLabel, wasmBackwardLabel)
                for label in s.labels {
                    if label in funcGotoTable {
                        throw MError("Duplicate label name", [s.mark])
                    }
                    funcGotoTable[label] = target
                }
            }
            startOfBlock = false
        }
        var out: List[Binaryen.Expression] = []
        for s in stmts {
            if s.labels {
                val gotoTarget = funcGotoTable[s.labels[0]]
                gotoTarget.passed = true
                out = [m.block(null(gotoTarget.forwardLabel), out, auto)]
            }
            out.add(stmtInBlock(s))
        }
        if val blabel = backwardLabel {
            out = [m.loop(null(blabel), m.block(null, out, auto))]
        }
        for s in stmts {
            if s.labels {
                val gotoTarget = funcGotoTable[s.labels[0]]
                gotoTarget.expired = true
            }
        }
        out
    }

    def stmt(self, stmt: C2IR.Stmt): Binaryen.Expression {
        when stmt.kind {
            case nop = m.nop()
            case block = block(stmt)
            case ret {
                if val func = currentFunc {
                    when func.type.returnType {
                        case derived(..) {
                            Assert(stmt.expr.type.isDerived())
                            m.block(null, [
                                # Copy the returning derived to the memory
                                # pointed to by the derived return pointer.
                                _dropsetderef(
                                    stmt.mark,
                                    func.type.returnType,
                                    0,  # dest offset
                                    m.local.get(retptrLocalIndex.get(), i32),  # dest ptr
                                    expr(stmt.expr), # src ptr
                                ),
                                restoreSP(),
                                m.returnVoid(),
                            ], none)
                        }
                        else {
                            _withLocalSet(stmt.expr.type, expr(stmt.expr), (localRetVar, assign) -> {
                                m.block(null, [
                                    assign,
                                    restoreSP(),
                                    m.return_(m.local.get(localRetVar, type(stmt.expr.type))),
                                ], auto)
                            })
                        }
                    }
                } else {
                    throw MError("return only be used inside a function definition", [stmt.mark])
                }
            }
            case expr = dropexpr(stmt.expr)
            case if_ = m.if_(expr(stmt.cond), stmt(stmt.then), stmt(stmt.els))
            case whileEx {
                val savedBreakLabel = currentBreakLabel
                val savedContinueLabel = currentContinueLabel
                val breakLabel = newLabel()
                val continueLabel = newLabel()
                currentBreakLabel = null(breakLabel)
                if stmt.handleContinue { currentContinueLabel = null(continueLabel) }
                val cond = expr(stmt.cond)
                val then = stmt(stmt.then)
                val ret = if stmt.incr.isPure() {
                    m.block(null(breakLabel), [
                        m.loop(null(continueLabel), m.block(null, [
                            m.br_if(breakLabel, m.i32.eqz(cond)),
                            then,
                            m.br(continueLabel),
                        ], none))
                    ], none)
                } else {
                    val incr = dropexpr(stmt.incr)
                    val firstFlag = newLocal(i32)
                    m.block(null(breakLabel), [
                        m.local.set(firstFlag, m.i32.const(0)),
                        m.loop(null(continueLabel), m.block(null, [
                            m.if_(
                                m.local.get(firstFlag, i32),
                                incr,
                                m.nop()),
                            m.local.set(firstFlag, m.i32.const(1)),
                            m.br_if(breakLabel, m.i32.eqz(cond)),
                            then,
                            m.br(continueLabel),
                        ], none))
                    ], none)
                }
                currentBreakLabel = savedBreakLabel
                currentContinueLabel = savedContinueLabel
                ret
            }
            case break_ {
                if val breakLabel = currentBreakLabel {
                    m.br(breakLabel)
                } else {
                    throw MError("Misplaced break statement", [stmt.mark])
                }
            }
            case continue_ {
                if val continueLabel = currentContinueLabel {
                    m.br(continueLabel)
                } else {
                    throw MError("Misplaced continue statement", [stmt.mark])
                }
            }
            case goto = if val target = funcGotoTable.getOrNull(stmt.targetLabel) {
                if target.passed {
                    if val backwardLabel = target.backwardLabel {
                        if target.expired {
                            throw MError("Jumping into a block is not supported", [stmt.mark])
                        } else {
                            m.br(backwardLabel)
                        }
                    } else {
                        throw MError(
                            "Backward gotos are only supported to the beginning " +
                                "of a block",
                            [stmt.mark])
                    }
                } else {
                    m.br(target.forwardLabel)
                }
            } else { throw MError("label " + stmt.targetLabel + " not found", [stmt.mark]) }
            else = throw MError("TODO codegen stmt " + stmt.kind, [stmt.mark])
        }
    }

    def nop(self): Binaryen.Expression = m.nop()

    def dropsetvar(self, mark: Mark, var_: C2IR.Var, expr: C2IR.Expr): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        _dropsetderef(mark, var_.type, offset, stackPtr, expr(expr))
    }

    ## zero out a variable
    def zerovar(self, mark: Mark, var_: C2IR.Var): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        _memset(mark, offset, stackPtr, 0, var_.type.size())
    }

    def dropsetgvar(self, mark: Mark, gvar: C2IR.GVar, expr: C2IR.Expr): Binaryen.Expression {
        val offset = getGlobalOffset(gvar)
        _dropsetderef(mark, gvar.type, offset, m.i32.const(0), expr(expr))
    }

    def teevar(self, mark: Mark, var_: C2IR.Var, expr: C2IR.Expr): Binaryen.Expression {
        m.block(null, [dropsetvar(mark, var_, expr), getvar(mark, var_)], auto)
    }

    def teegvar(self, mark: Mark, gvar: C2IR.GVar, expr: C2IR.Expr): Binaryen.Expression {
        m.block(null, [dropsetgvar(mark, gvar, expr), getgvar(mark, gvar)], auto)
    }

    def getvar(self, mark: Mark, var_: C2IR.Var): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        _getderef(mark, var_.type, offset, stackPtr)
    }

    def getgvar(self, mark: Mark, gvar: C2IR.GVar): Binaryen.Expression {
        val offset = getGlobalOffset(gvar)
        _getderef(mark, gvar.type, offset, m.i32.const(0))
    }

    def addrvar(self, var_: C2IR.Var): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        m.i32.add(m.i32.const(offset), stackPtr)
    }

    def addrgvar(self, gvar: C2IR.GVar): Binaryen.Expression {
        val offset = getGlobalOffset(gvar)
        m.i32.const(offset)
    }

    def deref(self, expr: C2IR.Expr): Binaryen.Expression {
        Assert(expr.type.isPtr())
        _getderef(expr.mark, expr.type.base, 0, expr(expr))
    }

    def _getderef(
            self,
            mark: Mark,
            valtype: C2IR.Type,
            offset: Int,
            addrExpr: Binaryen.Expression): Binaryen.Expression {
        when valtype {
            case void; case int; case ptr(..) = m.i32.load(offset, 0, addrExpr)
            case bool = int2bool(m.i32.load8_u(offset, 0, addrExpr))
            case char = m.i32.load8_u(offset, 0, addrExpr)
            case short = m.i32.load16_s(offset, 0, addrExpr)
            case long = m.i64.load(offset, 0, addrExpr)
            case array(..); case derived(..) {
                # array, derived type values cannot be stored in a register, so
                # instead in these cases we just return the address as is
                if offset { m.i32.add(m.i32.const(offset), addrExpr) } else { addrExpr }
            }
            else = throw MError("TODO _getderef " + valtype, [mark])
        }
    }

    def _dropsetderef(
            self,
            mark: Mark,
            valtype: C2IR.Type,
            offset: Int,
            addrExpr: Binaryen.Expression,
            valExpr: Binaryen.Expression): Binaryen.Expression {
        when valtype {
            case void = throw MError("Assignment to void type is not allowed", [mark])
            case int; case ptr(..) { m.i32.store(offset, 0, addrExpr, valExpr) }
            case long { m.i64.store(offset, 0, addrExpr, valExpr) }
            case char = m.i32.store8(offset, 0, addrExpr, valExpr)
            case bool = m.i32.store8(offset, 0, addrExpr, int2bool(valExpr))
            case short = m.i32.store16(offset, 0, addrExpr, valExpr)
            case array(..) = throw MError("Assignment to array type is not allowed", [mark])
            case derived(x) = _memcpy(mark, offset, addrExpr, valExpr, x.size())
            else = throw MError("TODO _dropsetderef " + valtype, [mark])
        }
    }

    ## Effectively a compile time memcpy
    def _memcpy(
            self,
            mark: Mark,
            destOffset: Int,
            destAddrExpr: Binaryen.Expression,
            srcAddrExpr: Binaryen.Expression,
            size: Int): Binaryen.Expression {
        val voidp = C2IR.Type.void.ptrOf()
        _withLocalSet(voidp, destAddrExpr, (destLocal, destAssignExpr) ->
            _withLocalSet(voidp, srcAddrExpr, (srcLocal, srcAssignExpr) -> {
                val exprs = [destAssignExpr, srcAssignExpr]
                var i = 0
                for ; i < size; i++ {
                    exprs.add(m.i32.store8(
                        # write to (destOffset + i + dest)
                        destOffset + i, 0, m.local.get(destLocal, i32),
                        # read from (i + src)
                        m.i32.load8_u(i, 0, m.local.get(srcLocal, i32))))
                }
                m.block(null, exprs, none)
            }))
    }

    ## Effectively a compile time memset
    def _memset(
            self,
            mark: Mark,
            destOffset: Int,
            destAddrExpr: Binaryen.Expression,
            value: Int,
            size: Int): Binaryen.Expression {
        val voidp = C2IR.Type.void.ptrOf()
        _withLocalSet(voidp, destAddrExpr, (destLocal, destAssignExpr) -> {
            val exprs = [destAssignExpr]
            var i = 0
            for ; i < size; i++ {
                exprs.add(m.i32.store8(
                    # write to (destOffset + i + dest)
                    destOffset + i, 0, m.local.get(destLocal, i32),
                    # read from (i + src)
                    m.i32.const(value)))
            }
            m.block(null, exprs, none)
        })
    }

    def _teederef(
            self,
            mark: Mark,
            valtype: C2IR.Type,
            offset: Int,
            addrExpr: Binaryen.Expression,
            valExpr: Binaryen.Expression): Binaryen.Expression {
        val valbtype = type(valtype)
        _withLocalSet(valtype, valExpr, (local, assignExpr) -> m.block(null, [
            assignExpr,
            _dropsetderef(mark, valtype, offset, addrExpr, m.local.get(local, valbtype)),
            m.local.get(local, valbtype),
        ], auto))
    }

    def dropsetderef(self, mark: Mark, addrExpr: C2IR.Expr, valExpr: C2IR.Expr): Binaryen.Expression {
        _dropsetderef(mark, valExpr.type, 0, expr(addrExpr), expr(valExpr))
    }

    def teederef(self, mark: Mark, addrExpr: C2IR.Expr, valExpr: C2IR.Expr): Binaryen.Expression {
        _teederef(mark, valExpr.type, 0, expr(addrExpr), expr(valExpr))
    }

    def dropexpr(self, expr: C2IR.Expr): Binaryen.Expression {
        when expr.kind {
            case setvar = dropsetvar(expr.mark, expr.var_, expr.arg)
            case setgvar = dropsetgvar(expr.mark, expr.gvar, expr.arg)
            case setderef = dropsetderef(expr.mark, expr.lhs, expr.rhs)
            case setmember = dropsetmember(expr.mark, expr.lhs, expr.member, expr.rhs)
            else = m.drop(expr(expr))
        }
    }

    def strlit(self, mark: Mark, value: Uint8Array): Int {
        if value not in strlitCache {
            strlitCache[value] = getCurrentInitDataEnd()
            initData.addBuffer(value)
            initData.addUint8(0)
        }
        strlitCache[value]
    }

    def getmember(
            self,
            mark: Mark,
            derivedExpr: C2IR.Expr,
            member: C2IR.Type.Derived.Member): Binaryen.Expression {
        _getderef(
            mark,
            member.type,
            member.offset,
            expr(derivedExpr)) # derived exprs should resolve to ptrs like arrays
    }

    def dropsetmember(
            self,
            mark: Mark,
            derivedExpr: C2IR.Expr,
            member: C2IR.Type.Derived.Member,
            valExpr: C2IR.Expr): Binaryen.Expression {
        _dropsetderef(
            mark,
            member.type,
            member.offset,
            expr(derivedExpr), # derived exprs should resovle to ptrs like arrays
            expr(valExpr))
    }

    def teemember(
            self,
            mark: Mark,
            derivedExpr: C2IR.Expr,
            member: C2IR.Type.Derived.Member,
            valExpr: C2IR.Expr): Binaryen.Expression {
        _teederef(
            mark,
            member.type,
            member.offset,
            expr(derivedExpr), # derived exprs should resolve to ptrs like arrays
            expr(valExpr))
    }

    def withMark(self, mark: Mark, expr: Binaryen.Expression): Binaryen.Expression {
        if enableStackTrace {
            # NOTE: Unfortunately, if there are nested function calls, this will cause
            # multiple entries in the stack trace for the same line.
            # However, avoiding this would probably create a large number of local
            # variables for each function call.
            # For now, we just accept this tradeoff.
            val exprType = Binaryen.getExpressionType(expr)
            val localIndex = newLocal(exprType)
            val funcNameIndex = getDebugNameIndex(currentFunc.map(f -> f.name).getOr(""))
            val fileNameIndex = getDebugNameIndex(mark.filepath)
            # NOTE: C-void is mapped to Binaryen.i32
            m.block(null, [
                m.call("__push", [
                    m.i32.const(funcNameIndex),
                    m.i32.const(fileNameIndex),
                    m.i32.const(mark.line)], none),
                m.local.set(localIndex, expr),
                m.call("__pop", [], none),
                m.local.get(localIndex, exprType),
            ], auto)
        } else {
            expr
        }
    }

    def _casterr(self, ce: C2IR.Expr): NoReturn {
        throw MError("" + ce.arg.type + " to " + ce.type + " casts are not supported", [ce.mark])
    }

    def int2bool(self, expr: Binaryen.Expression): Binaryen.Expression {
        m.i32.xor(m.i32.const(1), m.i32.eqz(expr))
    }

    def cast(self, expr: C2IR.Expr): Binaryen.Expression {
        Assert.equal(expr.kind, C2IR.Expr.Kind.cast)
        if expr.type.isVoid() {
            return m.block(null, [dropexpr(expr.arg), m.i32.const(0)], auto)
        }
        when expr.arg.type {
            case int;case ptr(..) = when expr.type {
                case bool = int2bool(expr(expr.arg))
                case char = {
                    m.i32.and_(m.i32.const(0xFF), expr(expr.arg))
                }
                # case short = m.i32.and_(m.i32.const(0xFFFF), expr(expr.arg))
                case int;case ptr(..) = expr(expr.arg)
                case long = m.i64.extend_s(expr(expr.arg))
                else = _casterr(expr)
            }
            case bool = when expr.type {
                case char; case short; case int = expr(expr.arg)
                else = _casterr(expr)
            }
            case char = when expr.type {
                case bool = int2bool(expr(expr.arg))
                case short;case int;case ptr(..) = expr(expr.arg)
                else = _casterr(expr)
            }
            case short = when expr.type {
                case bool = int2bool(expr(expr.arg))
                case char = m.i32.and_(m.i32.const(0xFF), expr(expr.arg))
                case int;case ptr(..) = expr(expr.arg)
                else = _casterr(expr)
            }
            case long = when expr.type {
                case char = m.i32.and_(m.i32.const(0xFF), m.i32.wrap(expr(expr.arg)))
                case short = m.i32.and_(m.i32.const(0xFFFF), m.i32.wrap(expr(expr.arg)))
                case int;case ptr(..) = m.i32.wrap(expr(expr.arg))
                else = _casterr(expr)
            }
            else = _casterr(expr)
        }
    }

    def expr(self, expr: C2IR.Expr): Binaryen.Expression {
        when expr.kind {
            case int; case short = m.i32.const(expr.intValue)
            case intNeg = m.i32.sub(m.i32.const(0), expr(expr.arg))
            case intAdd = m.i32.add(expr(expr.lhs), expr(expr.rhs))
            case intSub = m.i32.sub(expr(expr.lhs), expr(expr.rhs))
            case intMul = m.i32.mul(expr(expr.lhs), expr(expr.rhs))
            case intDiv = m.i32.div_s(expr(expr.lhs), expr(expr.rhs))
            case intRem = m.i32.rem_s(expr(expr.lhs), expr(expr.rhs))
            case intEq = m.i32.eq(expr(expr.lhs), expr(expr.rhs))
            case intNe = m.i32.ne(expr(expr.lhs), expr(expr.rhs))
            case intLt = m.i32.lt_s(expr(expr.lhs), expr(expr.rhs))
            case intLe = m.i32.le_s(expr(expr.lhs), expr(expr.rhs))
            case intBitwiseNot = m.i32.xor(m.i32.const(-1), expr(expr.arg))
            case intBitwiseAnd = m.i32.and_(expr(expr.lhs), expr(expr.rhs))
            case intBitwiseOr = m.i32.or_(expr(expr.lhs), expr(expr.rhs))
            case intBitwiseXor = m.i32.xor(expr(expr.lhs), expr(expr.rhs))
            case intShl = m.i32.shl(expr(expr.lhs), expr(expr.rhs))
            case intShr = m.i32.shr_s(expr(expr.lhs), expr(expr.rhs))

            # char is unsigned
            case char = m.i32.const(expr.intValue)

            case long {
                # TODO: address this lie
                val i = js!(Int, "Number(", expr.bigIntValue, ")")

                # TODO: address truncation issues
                if expr.bigIntValue < 0n {
                    m.i64.sub(m.i64.const(0), m.i64.const(-i))
                } else {
                    m.i64.const(i)
                }
            }
            case longNeg = m.i64.sub(m.i64.const(0), expr(expr.arg))
            case longAdd = m.i64.add(expr(expr.lhs), expr(expr.rhs))
            case longSub = m.i64.sub(expr(expr.lhs), expr(expr.rhs))
            case longMul = m.i64.mul(expr(expr.lhs), expr(expr.rhs))
            case longDiv = m.i64.div_s(expr(expr.lhs), expr(expr.rhs))
            case longRem = m.i64.rem_s(expr(expr.lhs), expr(expr.rhs))
            case longEq = m.i64.eq(expr(expr.lhs), expr(expr.rhs))
            case longNe = m.i64.ne(expr(expr.lhs), expr(expr.rhs))
            case longLt = m.i64.lt_s(expr(expr.lhs), expr(expr.rhs))
            case longLe = m.i64.le_s(expr(expr.lhs), expr(expr.rhs))

            case cast = cast(expr)

            case funcall {
                val args = expr.args.map(a -> expr(a))
                val rtype = type(expr.func.type.returnType)
                val fname = expr.func.name
                Assert.equal(expr.type, expr.func.type.returnType)
                when expr.type {
                    case derived(x) {
                        # If a function returns a derived, we need to allocate
                        # space for the derived to be stored. Further, we pass
                        # a pointer to this allocated space as an extra argument
                        # so that the function can write to it.
                        # The function's wasm return type should be 'none'.
                        val size = x.size()
                        val offset = alloca(size, x.alignment())
                        val outptr = m.i32.add(m.i32.const(offset), stackPtr)
                        args.add(outptr) # add result ptr
                        m.block(null, [
                            m.call(fname, args, none),
                            _memcpy(expr.mark, offset, stackPtr, outptr, size),
                            outptr,
                        ], auto)
                    }
                    else = withMark(expr.mark, m.call(fname, args, rtype))
                }
            }
            case str = m.i32.const(strlit(expr.mark, expr.bytesValue))
            case comma = m.block(null, [dropexpr(expr.lhs), expr(expr.rhs)], auto)
            case initzero = m.block(null, [
                zerovar(expr.mark, expr.var_),
                # Since this is an expression, it must return some value.
                # The return type of initzero was arbitrarily chosen to be int.
                m.i32.const(0),
            ], auto)
            case cond = m.if_(expr(expr.arg), expr(expr.lhs), expr(expr.rhs))
            case logicalNot = m.i32.eqz(expr(expr.arg))
            case logicalAnd = m.if_(expr(expr.lhs), expr(expr.rhs), m.i32.const(0))
            case logicalOr = m.if_(expr(expr.lhs), m.i32.const(1), expr(expr.rhs))
            case stmt = stmtExpr(expr)
            case addrvar = addrvar(expr.var_)
            case getvar = getvar(expr.mark, expr.var_)
            case setvar = teevar(expr.mark, expr.var_, expr.arg)
            case addrgvar = addrgvar(expr.gvar)
            case getgvar = getgvar(expr.mark, expr.gvar)
            case setgvar = teegvar(expr.mark, expr.gvar, expr.arg)
            case getmember = getmember(expr.mark, expr.arg, expr.member)
            case setmember = teemember(expr.mark, expr.lhs, expr.member, expr.rhs)
            case deref = deref(expr.arg)
            case setderef = teederef(expr.mark, expr.lhs, expr.rhs)
            case arrayToPtr = expr(expr.arg)
            case ptrAdd = m.i32.add(
                expr(expr.lhs),
                m.i32.mul(
                    m.i32.const(expr.lhs.type.base.size()),
                    expr(expr.rhs)))
            case ptrSub = m.i32.sub(
                expr(expr.lhs),
                m.i32.mul(
                    m.i32.const(expr.lhs.type.base.size()),
                    expr(expr.rhs)))
            case ptrDiff = m.i32.div_s(
                m.i32.sub(
                    expr(expr.lhs),
                    expr(expr.rhs)),
                m.i32.const(expr.lhs.type.base.size()))
            else = throw MError("TODO codegen expr " + expr.kind, [expr.mark])
        }
    }

    def tconst(self, type: Binaryen.Type, value: Int): Binaryen.Expression {
        if type == i32 {
            m.i32.const(value)
        } else if type == i64 {
            m.i64.const(value)
        } else {
            throw MError("TODO tconst " + js!(String, "''+", type), [])
        }
    }

    def tadd(
            self,
            type: Binaryen.Type,
            lhs: Binaryen.Expression,
            rhs: Binaryen.Expression): Binaryen.Expression {
        if type == i32 {
            m.i32.add(lhs, rhs)
        } else if type == i64 {
            m.i64.add(lhs, rhs)
        } else {
            throw MError("TODO tadd " + js!(String, "''+", type), [])
        }
    }
}
