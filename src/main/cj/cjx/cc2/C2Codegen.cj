package cjx.cc2

import cjx.parser.Mark
import cj.Error
import cjx.parser.MError
import cj.Uint8Array
import cjx.cc2.C2IR
import cjx.binaryen.Binaryen

class C2Codegen {
    private static val optimize = true
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto

    private val m: Binaryen.Module = Binaryen.Module()
    private var labelCount = 0
    private var localSlotSP = 0 # index of wasm local variable pointing to start of local stack
    private var locals: List[Binaryen.Type] = []
    private var cLocalOffsets: List[Int] = []

    def emit(self, tu: C2IR.TranslationUnit): Uint8Array {
        m.setMemory(1, 1)

        # initialize the stack pointer
        m.addGlobal("SP", i32, true, m.i32.const(8))

        for func in tu.funcs {
            func(func)
        }

        m.validate()
        if optimize { m.optimize() }
        # IO.println(m.emitText())
        m.emitBinary()
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

    def type(self, type: C2IR.Type): Binaryen.Type {
        when type {
            case void = i32
            case int = i32
            case ptr(..) = i32
            case func(..) = i32
            case struct_(..) = throw Error("TODO codegen type struct")
        }
    }

    def sizeOfType(self, type: C2IR.Type): Int {
        when type {
            case void = 4
            case int = 4
            case ptr(..) = 4
            case func(..) = 4
            case struct_(..) = throw Error("TODO codegen sizeOfType struct")
        }
    }

    def getLocalOffset(self, var_: C2IR.Var): Int = cLocalOffsets[var_.index]

    def __get_localStackPtr(self): Binaryen.Expression = m.local.get(localSlotSP, i32)

    def restoreSP(self): Binaryen.Expression {
        m.global.set("SP", m.local.get(localSlotSP, i32))
    }

    def func(self, func: C2IR.Func) {
        locals = []
        localSlotSP = newLocal(i32)
        Assert.equal(localSlotSP, 0)

        cLocalOffsets = []
        var nextCLocalOffset = 0
        val cLocals = func.locals
        var cLocalsByteSize = 0
        for i = 0; i < cLocals.size(); i++ {
            val var_ = cLocals[i]
            Assert.equal(i, var_.index)
            Assert.equal(i, cLocalOffsets.size())
            cLocalOffsets.add(cLocalsByteSize)
            cLocalsByteSize += sizeOfType(var_.type)
        }

        val stmts: List[Binaryen.Expression] = []

        # allocate space for C local variables on the stack
        stmts.add(m.local.set(localSlotSP, m.global.get("SP", i32)))
        stmts.add(m.global.set("SP",
            m.i32.add(m.global.get("SP", i32), m.i32.const(cLocalsByteSize))))

        val params = func.params
        for i = 0; i < params.size(); i++ {
            val param = params[i]
            val ptype = type(param.type)
            stmts.add(if ptype == i32 {
                m.i32.store(getLocalOffset(param), 0, localStackPtr, m.local.get(i, ptype))
            } else if ptype == i64 {
                m.i64.store(getLocalOffset(param), 0, localStackPtr, m.local.get(i, ptype))
            } else {
                throw Error("TODO")
            })
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
            else = throw MError("TODO codegen stmt " + stmt.kind, [stmt.mark])
        }
    }

    def nop(self): Binaryen.Expression = m.nop()

    def dropsetvar(self, mark: Mark, var_: C2IR.Var, expr: C2IR.Expr): Binaryen.Expression {
        val vartype = type(var_.type)
        val offset = getLocalOffset(var_)
        if vartype == i32 {
            m.i32.store(offset, 0, localStackPtr, expr(expr))
        } else if vartype == i64 {
            m.i64.store(offset, 0, localStackPtr, expr(expr))
        } else {
            throw MError("TODO dropsetvar " + js!(String, "''+", vartype), [mark])
        }
    }

    def teevar(self, mark: Mark, var_: C2IR.Var, expr: C2IR.Expr): Binaryen.Expression {
        m.block(null, [dropsetvar(mark, var_, expr), getvar(mark, var_)], auto)
    }

    def getvar(self, mark: Mark, var_: C2IR.Var): Binaryen.Expression {
        val vartype = type(var_.type)
        val offset = getLocalOffset(var_)
        if vartype == i32 {
            m.i32.load(offset, 0, localStackPtr)
        } else if vartype == i64 {
            m.i64.load(offset, 0, localStackPtr)
        } else {
            throw MError("TODO getvar " + js!(String, "''+", vartype), [mark])
        }
    }

    def dropexpr(self, expr: C2IR.Expr): Binaryen.Expression {
        when expr.kind {
            case setvar = dropsetvar(expr.mark, expr.var_, expr.arg)
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
            case getvar = getvar(expr.mark, expr.var_)
            case setvar = teevar(expr.mark, expr.var_, expr.arg)
            else = throw MError("TODO codegen expr " + expr.kind, [expr.mark])
        }
    }
}
