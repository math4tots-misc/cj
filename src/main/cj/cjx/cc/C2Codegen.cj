package cjx.cc

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
    private var locals: List[Binaryen.Type] = []
    private var cLocalOffsets: List[Int] = []
    private val initData: DynamicBuffer = DynamicBuffer([])
    private val cGlobalOffsets: Map[String, Int] = MapOf()
    private var cGlobalsEnd: Int = stackSize
    private val strlitCache: Map[Uint8Array, Int] = MapOf()
    private val debugNameCache: Map[String, Int] = MapOf()
    private val debugNames: List[String] = []
    private var currentFunc: C2IR.Func? = null

    class Result {
        val binary: Uint8Array
        val memDesc: C2MemDesc
        val names: List[String]  # for debugging/stacktrace
    }

    def emit(self, tu: C2IR.TranslationUnit): Result {
        m.addMemoryImport("0", "js", "memory")

        # reserve space for global variables
        for gvar in tu.gvars {
            Assert(gvar.name not in cGlobalOffsets)
            val alignment = gvar.type.alignment()
            cGlobalsEnd = alignTo(cGlobalsEnd, alignment)
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
        Result(
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

    def alignTo(n: Int, align: Int): Int = n.roundUp(align)

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
            case void = i32
            case char = i32
            case int = i32
            case array(..) = i32
            case ptr(..) = i32
            case func(..) = i32
            case struct_(..) = throw Error("TODO codegen type struct")
        }
    }

    def getLocalOffset(self, var_: C2IR.Var): Int = cLocalOffsets[var_.index]
    def getGlobalOffset(self, gvar: C2IR.GVar): Int = cGlobalOffsets[gvar.name]

    def __get_localStackPtr(self): Binaryen.Expression = m.local.get(localSlotSP, i32)

    def restoreSP(self): Binaryen.Expression {
        m.global.set("SP", m.local.get(localSlotSP, i32))
    }

    def func(self, func: C2IR.Func) {
        if not is_set!(func, body) {
            val returnType = type(func.type.returnType)
            val paramTypes = Binaryen.createType(func.type.paramTypes.map(t -> type(t)))
            m.addFunctionImport(func.name, "c", func.name, paramTypes, returnType)
            return ()
        }

        # IO.println(func.name + " -> " + func.body)

        locals = func.params.map(p -> type(p.type))
        localSlotSP = newLocal(i32)
        Assert.equal(localSlotSP, func.params.size())

        cLocalOffsets = []
        var nextCLocalOffset = 0
        val cLocals = func.locals.list
        var cLocalsByteSize = 0
        for i = 0; i < cLocals.size(); i++ {
            val var_ = cLocals[i]
            Assert.equal(i, var_.index)
            Assert.equal(i, cLocalOffsets.size())

            val alignment = var_.type.alignment()
            cLocalsByteSize = alignTo(cLocalsByteSize, alignment)
            Assert.equal(cLocalsByteSize % alignment, 0)
            cLocalOffsets.add(cLocalsByteSize)
            cLocalsByteSize += var_.type.size()
        }

        val stmts: List[Binaryen.Expression] = []
        currentFunc = null(func)

        # allocate space for C local variables on the stack
        stmts.add(m.global.set("SP",
            m.i32.sub(m.global.get("SP", i32), m.i32.const(cLocalsByteSize))))
        stmts.add(m.local.set(localSlotSP, m.global.get("SP", i32)))

        val params = func.params
        for i = 0; i < params.size(); i++ {
            val param = params[i]
            val ptype = type(param.type)
            stmts.add(_setderef(
                param.mark,
                param.type,
                getLocalOffset(param),
                localStackPtr,
                m.local.get(i, ptype)))
        }

        stmts.add(stmt(func.body))
        if func.name == "main" or func.type.returnType.isVoid() {
            # main function has an implicit "return 0"
            # functions that return void also have an implicit return at the end
            # (we translate void to i32 for convenience, so we still just return 0)
            stmts.add(restoreSP())
            stmts.add(m.return_(m.i32.const(0)))
        } else {
            stmts.add(m.unreachable())
        }
        val body = m.block(null, stmts, auto)
        val binaryenFunc = m.addFunction(
            func.name,
            Binaryen.createType(func.type.paramTypes.map(t -> type(t))),
            type(func.type.returnType),
            locals,
            body)

        m.addFunctionExport(func.name, func.name)
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

    def stmt(self, stmt: C2IR.Stmt): Binaryen.Expression {
        when stmt.kind {
            case nop = m.nop()
            case block = m.block(null, stmt.stmts.map(s -> stmt(s)), auto)
            case ret {
                _withLocalSet(stmt.expr.type, expr(stmt.expr), (localRetVar, assign) -> {
                    m.block(null, [
                        assign,
                        restoreSP(),
                        m.return_(m.local.get(localRetVar, type(stmt.expr.type))),
                    ], auto)
                })
            }
            case expr = dropexpr(stmt.expr)
            case if_ = m.if_(expr(stmt.cond), stmt(stmt.then), stmt(stmt.els))
            case while_ {
                val breakLabel = newLabel()
                val continueLabel = newLabel()
                val cond = expr(stmt.cond)
                val then = stmt(stmt.then)
                m.block(null(breakLabel), [
                    m.loop(null(continueLabel), m.block(null, [
                        m.br_if(breakLabel, m.i32.eqz(cond)),
                        then,
                        m.br(continueLabel),
                    ], none))
                ], none)
            }
            else = throw MError("TODO codegen stmt " + stmt.kind, [stmt.mark])
        }
    }

    def nop(self): Binaryen.Expression = m.nop()

    def dropsetvar(self, mark: Mark, var_: C2IR.Var, expr: C2IR.Expr): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        _setderef(mark, var_.type, offset, localStackPtr, expr(expr))
    }

    def dropsetgvar(self, mark: Mark, gvar: C2IR.GVar, expr: C2IR.Expr): Binaryen.Expression {
        val offset = getGlobalOffset(gvar)
        _setderef(mark, gvar.type, offset, m.i32.const(0), expr(expr))
    }

    def teevar(self, mark: Mark, var_: C2IR.Var, expr: C2IR.Expr): Binaryen.Expression {
        m.block(null, [dropsetvar(mark, var_, expr), getvar(mark, var_)], auto)
    }

    def teegvar(self, mark: Mark, gvar: C2IR.GVar, expr: C2IR.Expr): Binaryen.Expression {
        m.block(null, [dropsetgvar(mark, gvar, expr), getgvar(mark, gvar)], auto)
    }

    def getvar(self, mark: Mark, var_: C2IR.Var): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        _getderef(mark, var_.type, offset, localStackPtr)
    }

    def getgvar(self, mark: Mark, gvar: C2IR.GVar): Binaryen.Expression {
        val offset = getGlobalOffset(gvar)
        _getderef(mark, gvar.type, offset, m.i32.const(0))
    }

    def addrvar(self, var_: C2IR.Var): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        m.i32.add(m.i32.const(offset), localStackPtr)
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
            case char = m.i32.load8_u(offset, 0, addrExpr)
            case array(..); case struct_(..) {
                # array and struct values cannot be stored in a register, so
                # instead in these cases we just return the address as is
                if offset { m.i32.add(m.i32.const(offset), addrExpr) } else { addrExpr }
            }
            else = throw MError("TODO _getderef " + valtype, [mark])
        }
    }

    def _setderef(
            self,
            mark: Mark,
            valtype: C2IR.Type,
            offset: Int,
            addrExpr: Binaryen.Expression,
            valExpr: Binaryen.Expression): Binaryen.Expression {
        when valtype {
            case void; case int; case ptr(..) { m.i32.store(offset, 0, addrExpr, valExpr) }
            case char = m.i32.store8(offset, 0, addrExpr, valExpr)
            else = throw MError("TODO _setderef " + valtype, [mark])
        }
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
            _setderef(mark, valtype, offset, addrExpr, m.local.get(local, valbtype)),
            m.local.get(local, valbtype),
        ], auto))
    }

    def dropsetderef(self, mark: Mark, addrExpr: C2IR.Expr, valExpr: C2IR.Expr): Binaryen.Expression {
        _setderef(mark, valExpr.type, 0, expr(addrExpr), expr(valExpr))
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
            structExpr: C2IR.Expr,
            member: C2IR.Type.Struct.Member): Binaryen.Expression {
        _getderef(
            mark,
            member.type,
            member.offset,
            expr(structExpr)) # struct exprs should resolve to ptrs like arrays
    }

    def dropsetmember(
            self,
            mark: Mark,
            structExpr: C2IR.Expr,
            member: C2IR.Type.Struct.Member,
            valExpr: C2IR.Expr): Binaryen.Expression {
        _setderef(
            mark,
            member.type,
            member.offset,
            expr(structExpr), # struct exprs should resovle to ptrs like arrays
            expr(valExpr))
    }

    def teemember(
            self,
            mark: Mark,
            structExpr: C2IR.Expr,
            member: C2IR.Type.Struct.Member,
            valExpr: C2IR.Expr): Binaryen.Expression {
        _teederef(
            mark,
            member.type,
            member.offset,
            expr(structExpr), # struct exprs should resovle to ptrs like arrays
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

    def expr(self, expr: C2IR.Expr): Binaryen.Expression {
        when expr.kind {
            case int; case char = m.i32.const(expr.intValue)
            case intNeg; case charNeg = m.i32.sub(m.i32.const(0), expr(expr.arg))
            case intAdd; case charAdd = m.i32.add(expr(expr.lhs), expr(expr.rhs))
            case intSub; case charSub = m.i32.sub(expr(expr.lhs), expr(expr.rhs))
            case intMul; case charMul = m.i32.mul(expr(expr.lhs), expr(expr.rhs))
            case intDiv; case charDiv = m.i32.div_s(expr(expr.lhs), expr(expr.rhs))
            case intRem; case charRem = m.i32.rem_s(expr(expr.lhs), expr(expr.rhs))
            case intEq; case charEq = m.i32.eq(expr(expr.lhs), expr(expr.rhs))
            case intNe; case charNe = m.i32.ne(expr(expr.lhs), expr(expr.rhs))
            case intLt; case charLt = m.i32.lt_s(expr(expr.lhs), expr(expr.rhs))
            case intLe; case charLe = m.i32.le_s(expr(expr.lhs), expr(expr.rhs))
            case funcall = withMark(
                expr.mark,
                m.call(
                    expr.func.name,
                    expr.args.map(a -> expr(a)),
                    type(expr.func.type.returnType)))
            case str = m.i32.const(strlit(expr.mark, expr.bytesValue))
            case comma = m.block(null, [dropexpr(expr.lhs), expr(expr.rhs)], auto)
            case stmt = m.block(null, [stmt(expr.stmt), expr(expr.arg)], auto)
            case addrvar = addrvar(expr.var_)
            case getgvar = getgvar(expr.mark, expr.gvar)
            case setgvar = teegvar(expr.mark, expr.gvar, expr.arg)
            case getvar = getvar(expr.mark, expr.var_)
            case setvar = teevar(expr.mark, expr.var_, expr.arg)
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
            case postIncr; case postDecr {
                val sign = if expr.kind == C2IR.Expr.Kind.postIncr { 1 } else { -1 }
                val mark = expr.mark
                val incrAmount = sign * incrAmount(expr.type)
                val bvaltype = type(expr.type)
                val ptrLocalVar = newLocal(i32)
                val valLocalVar = newLocal(bvaltype)
                m.block(null, [
                    m.local.set(ptrLocalVar, expr(expr.arg)),
                    m.local.set(
                        valLocalVar,
                        _getderef(mark, expr.type, 0, m.local.get(ptrLocalVar, i32))),
                    _setderef(mark, expr.type, 0, m.local.get(ptrLocalVar, i32),
                        tadd(
                            bvaltype,
                            m.local.get(valLocalVar, bvaltype),
                            tconst(bvaltype, incrAmount)
                        )),
                    m.local.get(valLocalVar, bvaltype),
                ], auto)
            }
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

    def incrAmount(self, type: C2IR.Type): Int = when type {
        case int = 1
        case ptr(t) = t.base.size()
        else = throw MError("TODO incrAmount " + type, [])
    }
}
