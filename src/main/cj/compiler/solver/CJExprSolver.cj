package compiler.solver

import compiler.CJError
import compiler.CJIR
import compiler.CJIR.Expr
import compiler.CJIR.ExprData as ED
import compiler.CJAst
import compiler.CJAst.ExprData as AED
import compiler.CJScope
import compiler.solver.CJSolver

class CJExprSolver {
    val solver: CJSolver
    val scope: CJScope

    def solveExpr(self, expr: CJAst.Expr): Expr {
        val mark = expr.mark
        when expr.data {
            case unit = Expr(mark, solver.unitType, ED.unit)
            else = throw CJError("TODO solveExpr", [expr.mark])
        }
    }
}
