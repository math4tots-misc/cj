package cjx.cc2

import cj.DynamicBuffer
import cjx.cc2.C2MemDesc
import cjx.parser.Mark
import cj.Error
import cjx.parser.MError
import cj.Uint8Array
import cjx.cc2.C2IR
import cjx.binaryen.Binaryen

class C2Codegen {
    private static val optimize = false
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto
    private static val stackSize = 4096
    private static val initMemPageCount = 1
    private static val maxMemPageCount = 4096

    private val m: Binaryen.Module = Binaryen.Module()
    private var labelCount = 0
    private var localSlotSP = -1 # index of wasm local variable pointing to start of local stack
    private var locals: List[Binaryen.Type] = []
    private var cLocalOffsets: List[Int] = []
    private val initData: DynamicBuffer = DynamicBuffer([])

    def emit(self, tu: C2IR.TranslationUnit): Tuple[Uint8Array, C2MemDesc] {
        m.addMemoryImport("0", "js", "memory")
        m.setMemory(initMemPageCount, maxMemPageCount)

        # initialize the stack pointer
        m.addGlobal("SP", i32, true, m.i32.const(stackSize))

        for func in tu.funcs {
            func(func)
        }

        m.validate()
        if optimize { m.optimize() }
        # IO.println(m.emitText())
        (m.emitBinary(), C2MemDesc(
            initMemPageCount,
            maxMemPageCount,
            stackSize,        # initialized data offset
            initData.toDataView()))
    }

    def alignTo(n: Int, align: Int): Int = (n + align - 1) // align * align

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

        locals = func.params.map(p -> type(p.type))
        localSlotSP = newLocal(i32)
        Assert.equal(localSlotSP, func.params.size())

        cLocalOffsets = []
        var nextCLocalOffset = 0
        val cLocals = func.locals
        var cLocalsByteSize = 0
        for i = 0; i < cLocals.size(); i++ {
            val var_ = cLocals[i]
            Assert.equal(i, var_.index)
            Assert.equal(i, cLocalOffsets.size())

            val alignment = var_.type.alignment()
            val size = var_.type.size()
            if cLocalsByteSize % alignment != 0 {
                cLocalsByteSize += alignment - cLocalsByteSize % alignment
            }
            Assert.equal(cLocalsByteSize % alignment, 0)
            cLocalOffsets.add(cLocalsByteSize)
            cLocalsByteSize += size
        }

        val stmts: List[Binaryen.Expression] = []

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
        m.addFunction(
            func.name,
            Binaryen.createType(func.type.paramTypes.map(t -> type(t))),
            type(func.type.returnType),
            locals,
            body)
        m.addFunctionExport(func.name, func.name)
    }

    def stmt(self, stmt: C2IR.Stmt): Binaryen.Expression {
        when stmt.kind {
            case nop = m.nop()
            case block = m.block(null, stmt.stmts.map(s -> stmt(s)), auto)
            case ret = m.block(null, [restoreSP(), m.return_(expr(stmt.expr))], auto)
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

    def teevar(self, mark: Mark, var_: C2IR.Var, expr: C2IR.Expr): Binaryen.Expression {
        m.block(null, [dropsetvar(mark, var_, expr), getvar(mark, var_)], auto)
    }

    def getvar(self, mark: Mark, var_: C2IR.Var): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        _getderef(mark, var_.type, offset, localStackPtr)
    }

    def addrvar(self, var_: C2IR.Var): Binaryen.Expression {
        val offset = getLocalOffset(var_)
        m.i32.add(m.i32.const(offset), localStackPtr)
    }

    def deref(self, expr: C2IR.Expr): Binaryen.Expression {
        _getderef(expr.mark, expr.type, 0, expr(expr))
    }

    def _getderef(
            self,
            mark: Mark,
            valtype: C2IR.Type,
            offset: Int,
            addrExpr: Binaryen.Expression): Binaryen.Expression {
        when valtype {
            case void; case int; case ptr(..) = m.i32.load(offset, 0, addrExpr)
            case char = m.i32.load8_s(offset, 0, addrExpr)
            case array(..) {
                # array values cannot be stored in a register, so
                # instead in these case we just return a pointer to the array
                m.i32.add(m.i32.const(offset), addrExpr)
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

    def dropsetderef(self, mark: Mark, addrExpr: C2IR.Expr, valExpr: C2IR.Expr): Binaryen.Expression {
        _setderef(mark, valExpr.type, 0, expr(addrExpr), expr(valExpr))
    }

    def teederef(self, mark: Mark, addrExpr: C2IR.Expr, valExpr: C2IR.Expr): Binaryen.Expression {
        val valbtype = type(valExpr.type)
        withLocalSet(valExpr, (local, assignExpr) -> {
            m.block(null, [
                assignExpr,
                _setderef(mark, valExpr.type, 0, expr(addrExpr), m.local.get(local, valbtype)),
                m.local.get(local, valbtype)
            ], auto)
        })
    }

    def dropexpr(self, expr: C2IR.Expr): Binaryen.Expression {
        when expr.kind {
            case setvar = dropsetvar(expr.mark, expr.var_, expr.arg)
            case setderef = dropsetderef(expr.mark, expr.lhs, expr.rhs)
            else = m.drop(expr(expr))
        }
    }

    def expr(self, expr: C2IR.Expr): Binaryen.Expression {
        when expr.kind {
            case int = m.i32.const(expr.intValue)
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
            case funcall = m.call(
                expr.func.name, expr.args.map(a -> expr(a)), type(expr.func.type.returnType))
            case addrvar = addrvar(expr.var_)
            case getvar = getvar(expr.mark, expr.var_)
            case setvar = teevar(expr.mark, expr.var_, expr.arg)
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
