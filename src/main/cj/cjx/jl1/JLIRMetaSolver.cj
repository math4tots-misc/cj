package cjx.jl1

import cjx.jl1.JLMark
import cjx.jl1.JLIRExpr
import cjx.jl1.JLType
import cj.Error
import cjx.jl1.JLError
import cjx.jl1.JLIRExpressionSolver
import cjx.jl1.JLIRMetaVal
import cjx.jl1.JLAstMetaExpr
import cjx.jl1.JLIRLocalContext

@derive(new)
class JLIRMetaSolver {
    val lctx: JLIRLocalContext
    val esolver: JLIRExpressionSolver

    def solveTruthy(self, expr: JLAstMetaExpr): Bool {
        when solve(expr, JLIRMetaVal.Constraint.truthy()) {
            case number(x) = x != 0
            else = throw Error("FUBAR solveTruthy")
        }
    }

    def solveExpr(self, expr: JLAstMetaExpr, expectedType: Nullable[JLType]): JLIRExpr {
        val constraint = if null(type) = expectedType {
            JLIRMetaVal.Constraint.expr(type)
        } else {
            JLIRMetaVal.Constraint.anyExpr()
        }
        when solve(expr, constraint) {
            case expr(e) = e
            else = throw Error("FUBAR solveExpr")
        }
    }

    def solveAnyType(self, expr: JLAstMetaExpr): JLType {
        when solve(expr, JLIRMetaVal.Constraint.anyType()) {
            case type(t) = t
            else = throw Error("FUBAR solveAnyType")
        }
    }

    def solveAny(self, expr: JLAstMetaExpr): JLIRMetaVal = solve(
        expr, JLIRMetaVal.Constraint.any())

    def solve(self, expr: JLAstMetaExpr, constraint: JLIRMetaVal.Constraint): JLIRMetaVal {
        val value = solveUnchecked(expr, constraint)
        val mark = expr.mark
        when constraint {
            case any = value
            case anyType = when value {
                case type(t) = JLIRMetaVal.type(t)
                else = throw JLError("Expected type", [mark])
            }
            case anyExpr = when value {
                case expr(e) = JLIRMetaVal.expr(e)
                else = throw JLError("Expected expression", [mark])
            }
            case expr(type) = when value {
                # TODO: check types
                case expr(e) = JLIRMetaVal.expr(e)
                else = throw JLError("Expected expression", [mark])
            }
            case truthy = when value {
                case number(x) = value
                case string(s) = JLIRMetaVal.number(s.size())
                case list(list) = JLIRMetaVal.number(list.size())
                else = throw JLError("Expected boolean expression but got " + value, [mark])
            }
        }
    }

    private def solveUnchecked(
            self, expr: JLAstMetaExpr, constraint: JLIRMetaVal.Constraint): JLIRMetaVal {
        when expr.data {
            case value(x) = x
            case type(t) = JLIRMetaVal.type(lctx.solveType(t))
            case expr(e) = {
                JLIRMetaVal.expr(esolver.solveExpression(e, when constraint {
                    case expr(t) = null(t)
                    else = null
                }))
            }
            case name(name) = {
                if null(arg) = lctx.getTemplateArgumentOrNull(name) {
                    when arg {
                        case int(i) = JLIRMetaVal.number(i)
                        case type(t) = JLIRMetaVal.type(t)
                    }
                } else {
                    throw JLError("Name " + name + " not found", [expr.mark])
                }
            }
            case apply(f, args) = {
                val mark = expr.mark
                switch f {
                    case "cond" = {
                        if args.size() % 2 != 0 {
                            throw JLError("cond requires an even number of arguments", [mark])
                        }
                        var result: Nullable[JLIRMetaVal] = null
                        for i = 0; result.isEmpty() and i < args.size(); i += 2 {
                            if solveTruthy(args[i]) {
                                result = null(solve(args[i + 1], constraint))
                            }
                        }
                        if null(v) = result {
                            v
                        } else {
                            throw JLError("cond with no matching branches", [mark])
                        }
                    }
                    case "eq" = {
                        checkArgc(mark, args, 2)
                        JLIRMetaVal.bool(solveAny(args[0]) == solveAny(args[1]))
                    }
                    else = throw JLError("Unrecognized meta form " + f, [mark])
                }
            }
        }
    }

    private def checkArgc(mark: JLMark, args: List[JLAstMetaExpr], argc: Int) {
        if args.size() != argc {
            throw JLError("Expected " + argc + " args but got " + args.size(), [mark])
        }
    }
}
