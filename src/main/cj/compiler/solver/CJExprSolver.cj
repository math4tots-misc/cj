package compiler.solver

import compiler.CJError
import compiler.CJIR
import compiler.CJIR.Expr
import compiler.CJIR.Type
import compiler.CJIR.ExprData as ED
import compiler.CJAst
import compiler.CJAst.ExprData as AED
import compiler.CJScope
import compiler.solver.CJSolver

class CJExprSolver {
    val solver: CJSolver
    val scope: CJScope
    val returnType: Type?

    def solveExprEx(self, expr: CJAst.Expr, expt: Type?): Expr {
        val mark = expr.mark
        when expr.data {
            case unit = Expr(mark, solver.unitType, ED.unit)
            case int(i) = Expr(mark, solver.intType, ED.int(i))
            else = throw CJError("TODO solveExpr", [expr.mark])
        }
    }
}
