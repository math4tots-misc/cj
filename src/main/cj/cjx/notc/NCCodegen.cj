package cjx.notc

import cjx.notc.NCError
import cjx.notc.NCIR
import cj.Uint8Array
import cjx.binaryen.Binaryen

class NCCodegen {
    private static val optimize = true
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto

    private val program: NCIR.Program
    private val m: Binaryen.Module = Binaryen.Module()

    def emit(program: NCIR.Program): Uint8Array {
        val self = Self(program)
        m.setMemory(1, 1024)
        for func in program.funcs {
            func(func)
        }
        m.validate()
        if optimize { m.optimize() }
        m.emitBinary()
    }

    def func(self, func: NCIR.Func) {
        # TODO: func args
        m.addFunction(
            func.name,
            Binaryen.createType(func.params.map(v -> type(v.type))),
            type(func.returnType),
            func.locals.map(v -> type(v.type)),
            expr(func.body))
        m.addFunctionExport(func.name, func.name)
    }

    def type(self, type: NCIR.Type): Binaryen.Type {
        when type {
            case int = i32
            case void = i32
        }
    }

    def expr(self, expr: NCIR.Expr): Binaryen.Expression {
        switch expr.kind {
            case NCIR.Expr.kINT = m.i32.const(expr.intValue)
            case NCIR.Expr.kINT_ADD = m.i32.add(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_SUB = m.i32.sub(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_MUL = m.i32.mul(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_DIV = m.i32.div_s(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_EQ = m.i32.eq(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_NE = m.i32.ne(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_LT = m.i32.lt_s(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kINT_LE = m.i32.le_s(expr(expr.lhs), expr(expr.rhs))
            case NCIR.Expr.kBLOCK {
                val bexprs: List[Binaryen.Expression] = []
                for stmt in expr.stmts[:-1] {
                    bexprs.add(m.drop(expr(stmt)))
                }
                bexprs.add(expr(expr.stmts[-1]))
                m.block(null, bexprs, type(expr.type))
            }
            else = throw NCError("TODO expr " + expr, [expr.mark])
        }
    }
}
