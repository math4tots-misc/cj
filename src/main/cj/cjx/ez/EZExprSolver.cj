package cjx.ez

import cjx.ez.EZError
import cjx.ez.EZIR
import cjx.ez.EZAst
import cjx.ez.EZSolver

@derive(new)
class EZExprSolver {
    val solver: EZSolver
    val localFactory: EZSolver.LocalFactory
    val scope: EZSolver.Scope

    def solve(self, astExpr: EZAst.Expr, expected: Nullable[EZIR.Type]): EZIR.Expr {
        val irExpr = solveRaw(astExpr, expected)
        if null(etype) = expected {
            implicitCast(irExpr, etype)
        } else {
            irExpr
        }
    }

    def solveRaw(self, astExpr: EZAst.Expr, expected: Nullable[EZIR.Type]): EZIR.Expr {
        when astExpr.data {
            case unit = EZIR.Expr(astExpr.mark, solver.getUnitType(), EZIR.ExprData.unit())
        }
    }

    def implicitCast(self, irExpr: EZIR.Expr, etype: EZIR.Type): EZIR.Expr {
        if irExpr.type == etype {
            irExpr
        } else {
            throw EZError("Expected " + etype + " but got " + irExpr.type, [irExpr.mark])
        }
    }
}
