package compiler.solver

import compiler.solver.CJSolverBaseMixin
import compiler.solver.CJScope
import cjx.parser.MError
import compiler.CJAst
import compiler.CJIR
import compiler.CJIR.Type

## Methods for doing best effort type inference
trait CJInferTypeMixin: CJSolverBaseMixin {

    def inferTypeOfAstOrNull(self, scope: CJScope, expr: CJAst.Expr): Type? {
        null(when expr.data {
            case unit = unitType
            case bool(..) = boolType
            case char(..) = charType
            case int(..) = intType
            case double(..) = doubleType
            case string(..) = stringType
            else = return null
        })
    }

    def inferTypeOfAst(self, scope: CJScope, expr: CJAst.Expr): Type = {
        if val t = inferTypeOfAstOrNull(scope, expr) { t } else {
            throw MError("Could not infer type of expression", [expr.mark])
        }
    }
}
