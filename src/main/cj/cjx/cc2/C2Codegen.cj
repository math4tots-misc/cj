package cjx.cc2

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

    private val m: Binaryen.Module = Binaryen.Module()
    private var labelCount = 0
    private var localSlotSP = 0
    private var locals: List[Binaryen.Type] = []

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

    def func(self, func: C2IR.Func) {
        locals = []
        localSlotSP = newLocal(i32)

        val stmts: List[Binaryen.Expression] = []

        val params = func.params
        for i = 0; i < params.size(); i++ {
            val param = params[i]
            val ptype = type(param.type)
            val spptr = m.local.get(localSlotSP, i32)
            stmts.add(if ptype == i32 {
                m.i32.store(param.index, 0, spptr, m.local.get(i, ptype))
            } else if ptype == i64 {
                m.i64.store(param.index, 0, spptr, m.local.get(i, ptype))
            } else {
                throw Error("TODO")
            })
        }

        stmts.add(stmt(func.body))
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
            case block {
                val out: List[Binaryen.Expression] = []
                for s in stmt.stmts {
                    out.add(stmt(s))
                }
                m.block(null, out, auto)
            }
            case ret = m.return_(expr(stmt.expr))
            else = throw MError("TODO codegen stmt " + stmt.kind, [stmt.mark])
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
            else = throw MError("TODO codegen expr " + expr.kind, [expr.mark])
        }
    }
}
