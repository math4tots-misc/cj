package cjx.cc

import cjx.cc.CCError
import cj.Uint8Array
import cjx.cc.CCIR
import cjx.binaryen.Binaryen

class CCCodegen {
    private static val none: Binaryen.Type = Binaryen.none
    private static val i32: Binaryen.Type = Binaryen.i32
    private static val i64: Binaryen.Type = Binaryen.i64
    private static val f32: Binaryen.Type = Binaryen.f32
    private static val f64: Binaryen.Type = Binaryen.f64
    private static val unreachable: Binaryen.Type = Binaryen.unreachable
    private static val auto: Binaryen.Type = Binaryen.auto

    private val m: Binaryen.Module = Binaryen.Module()

    def emit(self, expr: CCIR.Node): Uint8Array {
        val outExpr = expr(expr)

        m.addFunction("main", Binaryen.createType([]), i32, [], m.block(
            null,
            [expr(expr)],
            auto))
        m.addFunctionExport("main", "main")

        m.emitBinary()
    }

    def expr(self, expr: CCIR.Node): Binaryen.Expression {
        when expr.kind {
            case int = m.i32.const(expr.intValue)
            case neg = m.i32.sub(m.i32.const(0), expr(expr.arg))
            case pos = expr(expr.arg)
            case add = m.i32.add(expr(expr.lhs), expr(expr.rhs))
            case sub = m.i32.sub(expr(expr.lhs), expr(expr.rhs))
            case mul = m.i32.mul(expr(expr.lhs), expr(expr.rhs))
            case div = m.i32.div_s(expr(expr.lhs), expr(expr.rhs))
            case eq = m.i32.eq(expr(expr.lhs), expr(expr.rhs))
            case ne = m.i32.ne(expr(expr.lhs), expr(expr.rhs))
            case lt = m.i32.lt_s(expr(expr.lhs), expr(expr.rhs))
            case le = m.i32.le_s(expr(expr.lhs), expr(expr.rhs))
            else = throw CCError("TODO expr " + expr.kind, [expr.mark])
        }
    }
}
