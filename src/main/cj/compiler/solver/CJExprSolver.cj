package compiler.solver

import cjx.parser.MError
import compiler.CJIR
import compiler.CJIR.Expr
import compiler.CJIR.Type
import compiler.CJIR.ExprData as ED
import compiler.CJAst
import compiler.CJAst.ExprData as AED
import compiler.solver.CJScope
import compiler.solver.CJSolver

class CJExprSolver {
    val solver: CJSolver
    val scope: CJScope
    val returnType: Type?

    def solveExprEx(self, astExpr: CJAst.Expr, expt: Type?): Expr {
        # TODO
        # Expr(astExpr.mark, solver.unitType, ED.unit)
        val expr = solveExprExUnchecked(astExpr, expt)
        if val et = expt {
            # TODO: Implicits
            val at = expr.type
            if at != et and at != solver.noreturnType and et != solver.unitType {
                throw MError("TODO solveExprEx at = " + at + ", et = " + et, [expr.mark])
            }
        }
        expr
    }

    private def solveExprExUnchecked(self, astExpr: CJAst.Expr, expt: Type?): Expr {
        val mark = astExpr.mark
        when astExpr.data {
            case unit = Expr(mark, solver.unitType, ED.unit)
            case bool(x) = Expr(mark, solver.boolType, ED.bool(x))
            case char(x) = Expr(mark, solver.charType, ED.char(x))
            case int(x) = Expr(mark, solver.intType, ED.int(x))
            case double(x) = Expr(mark, solver.doubleType, ED.double(x))
            case string(x) = Expr(mark, solver.stringType, ED.string(x))
            case bigint(x) = Expr(mark, solver.bigintType, ED.bigint(x))

            case block(..) = throw MError("TODO solveExpr block", [mark])
            case call(ownerType, methodName, ..) = throw MError("TODO solveExpr call " + ownerType + ", " + methodName, [mark])
            case callname(name, ..) = throw MError("TODO solveExpr callname " + name, [mark])
            case decl(..) = throw MError("TODO solveExpr decl", [mark])
            case getvar(..) = throw MError("TODO solveExpr getvar", [mark])
            case setvar(..) = throw MError("TODO solveExpr setvar", [mark])
            case augvar(..) = throw MError("TODO solveExpr augvar", [mark])
            case getfield(..) = throw MError("TODO solveExpr getfield", [mark])
            case setfield(..) = throw MError("TODO solveExpr setfield", [mark])
            case augfield(..) = throw MError("TODO solveExpr augfield", [mark])
            case getstatic(..) = throw MError("TODO solveExpr getstatic", [mark])
            case setstatic(..) = throw MError("TODO solveExpr setstatic", [mark])
            case augstatic(..) = throw MError("TODO solveExpr augstatic", [mark])
            case logicalNot(..) = throw MError("TODO solveExpr logicalNot", [mark])
            case logicalAnd(..) = throw MError("TODO solveExpr logicalAnd", [mark])
            case logicalOr(..) = throw MError("TODO solveExpr logicalOr", [mark])
            case is_(..) = throw MError("TODO solveExpr is_", [mark])

            case null_(astSpecifiedInnerType, astInnerExpr) {
                val nullableInnerType = if val sit = astSpecifiedInnerType {
                    null(solver.solveType(scope, sit))
                } else {
                    if val et = expt {
                        when et {
                            case reified(rt) = if rt.defn.name == "cj.Nullable" {
                                null(rt.args[0]) } else { null }
                            else = null
                        }
                    } else { null }
                }
                val innerExpr = if val ie = astInnerExpr {
                    null(solveExprEx(ie, nullableInnerType))
                } else { null }
                val innerType = if val it = nullableInnerType { it } else if val ie = innerExpr {
                    ie.type
                } else { throw MError("Could not infer type of null", [mark]) }
                Expr(mark, solver.getNullableType(mark, innerType), ED.null_(innerExpr))
            }

            case list(..) = throw MError("TODO solveExpr list", [mark])
            case tuple(..) = throw MError("TODO solveExpr tuple", [mark])
            case if_(..) = throw MError("TODO solveExpr if_", [mark])
            case ifNull(..) = throw MError("TODO solveExpr ifNull", [mark])
            case while_(..) = throw MError("TODO solveExpr while_", [mark])
            case for_(..) = throw MError("TODO solveExpr for_", [mark])
            case when_(..) = throw MError("TODO solveExpr when_", [mark])
            case switch_(..) = throw MError("TODO solveExpr switch_", [mark])
            case lambda(..) = throw MError("TODO solveExpr lambda", [mark])
            case return_(..) = throw MError("TODO solveExpr return_", [mark])
            case await_(..) = throw MError("TODO solveExpr await_", [mark])
            case throw_(..) = throw MError("TODO solveExpr throw_", [mark])
            case try_(..) = throw MError("TODO solveExpr try_", [mark])
            case macro(..) = throw MError("TODO solveExpr macro", [mark])
            case type(..) = throw MError("TODO solveExpr type", [mark])
        }
    }
}
