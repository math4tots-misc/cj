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

    def solveExprEx(self, astExpr: CJAst.Expr, expt: Type?): Expr {
        # TODO
        # Expr(astExpr.mark, solver.unitType, ED.unit)
        val expr = solveExprExUnchecked(astExpr, expt)
        if val et = expt {
            # TODO: Implicits
            val at = expr.type
            if at != et and at != solver.noreturnType and et != solver.unitType {
                throw CJError("TODO solveExprEx at = " + at + ", et = " + et, [expr.mark])
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

            case block(..) = throw CJError("TODO solveExpr block", [mark])
            case call(ownerType, methodName, ..) = throw CJError("TODO solveExpr call " + ownerType + ", " + methodName, [mark])
            case callname(name, ..) = throw CJError("TODO solveExpr callname " + name, [mark])
            case decl(..) = throw CJError("TODO solveExpr decl", [mark])
            case getvar(..) = throw CJError("TODO solveExpr getvar", [mark])
            case setvar(..) = throw CJError("TODO solveExpr setvar", [mark])
            case augvar(..) = throw CJError("TODO solveExpr augvar", [mark])
            case getfield(..) = throw CJError("TODO solveExpr getfield", [mark])
            case setfield(..) = throw CJError("TODO solveExpr setfield", [mark])
            case augfield(..) = throw CJError("TODO solveExpr augfield", [mark])
            case getstatic(..) = throw CJError("TODO solveExpr getstatic", [mark])
            case setstatic(..) = throw CJError("TODO solveExpr setstatic", [mark])
            case augstatic(..) = throw CJError("TODO solveExpr augstatic", [mark])
            case logicalNot(..) = throw CJError("TODO solveExpr logicalNot", [mark])
            case logicalAnd(..) = throw CJError("TODO solveExpr logicalAnd", [mark])
            case logicalOr(..) = throw CJError("TODO solveExpr logicalOr", [mark])
            case is_(..) = throw CJError("TODO solveExpr is_", [mark])

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
                } else { throw CJError("Could not infer type of null", [mark]) }
                Expr(mark, solver.getNullableType(mark, innerType), ED.null_(innerExpr))
            }

            case list(..) = throw CJError("TODO solveExpr list", [mark])
            case tuple(..) = throw CJError("TODO solveExpr tuple", [mark])
            case if_(..) = throw CJError("TODO solveExpr if_", [mark])
            case ifNull(..) = throw CJError("TODO solveExpr ifNull", [mark])
            case while_(..) = throw CJError("TODO solveExpr while_", [mark])
            case for_(..) = throw CJError("TODO solveExpr for_", [mark])
            case when_(..) = throw CJError("TODO solveExpr when_", [mark])
            case switch_(..) = throw CJError("TODO solveExpr switch_", [mark])
            case lambda(..) = throw CJError("TODO solveExpr lambda", [mark])
            case return_(..) = throw CJError("TODO solveExpr return_", [mark])
            case await_(..) = throw CJError("TODO solveExpr await_", [mark])
            case throw_(..) = throw CJError("TODO solveExpr throw_", [mark])
            case try_(..) = throw CJError("TODO solveExpr try_", [mark])
            case macro(..) = throw CJError("TODO solveExpr macro", [mark])
            case type(..) = throw CJError("TODO solveExpr type", [mark])
        }
    }
}
