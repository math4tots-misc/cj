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
    var currentScope: JLIRMetaVal.Scope = JLIRMetaVal.Scope(null)

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

    def solveString(self, expr: JLAstMetaExpr): String = {
        val value = solveAny(expr)
        when value {
            case string(s) = s
            else = throw JLError("Expected string but got " + value, [expr.mark])
        }
    }

    def solveList(self, expr: JLAstMetaExpr): List[JLIRMetaVal] = {
        val value = solveAny(expr)
        when value {
            case list(list) = list
            else = throw JLError("Expected list but got " + value, [expr.mark])
        }
    }

    def solveExprList(self, expr: JLAstMetaExpr): List[JLIRExpr] = {
        solveList(expr).map(item -> when item {
            case expr(e) = e
            else = throw JLError("Expected expression but got " + item, [expr.mark])
        })
    }

    def solveLambda(self, expr: JLAstMetaExpr): Tuple[JLIRMetaVal.Scope, List[String], List[JLAstMetaExpr]] {
        val value = solveAny(expr)
        when value {
            case lambda(scope, argnames, body) = (scope, argnames, body)
            else = throw JLError("Expected lambda but got " + value, [expr.mark])
        }
    }

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
                if null(arg) = currentScope.getOrNull(name) {
                    arg
                } else if null(arg) = lctx.getTemplateArgumentOrNull(name) {
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
                    case "begin" = {
                        if args {
                            for i = 0; i + 1 < args.size(); i++ {
                                solveAny(args[i])
                            }
                            solve(args.last(), constraint)
                        } else {
                            Default()
                        }
                    }
                    case "define" = {
                        checkArgc(mark, args, 2)
                        val name = getRawName(args[0])
                        val value = solveAny(args[1])
                        currentScope[name] = value
                        Default()
                    }
                    case "lambda" = {
                        checkMinArgc(mark, args, 1)
                        val argnames = getRawNameList(args[0])
                        val body = args[1:]
                        JLIRMetaVal.lambda(currentScope, argnames, body)
                    }
                    case "apply" = {
                        checkMinArgc(mark, args, 1)
                        val oldScope = currentScope
                        val (outerLambdaScope, argnames, body) = solveLambda(args[0])
                        currentScope = JLIRMetaVal.Scope(null(outerLambdaScope))
                        for i = 0; i < argnames.size(); i++ {
                            if i + 1 < args.size() {
                                currentScope[argnames[i]] = solveAny(args[i + 1])
                            } else {
                                currentScope[argnames[i]] = Default()
                            }
                        }
                        val result = if body {
                            for i = 0; i + 1 < body.size(); i++ {
                                solveAny(body[i])
                            }
                            solve(body.last(), constraint)
                        } else {
                            Default()
                        }
                        currentScope = oldScope
                        result
                    }
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
                    case "list" = {
                        JLIRMetaVal.list(args.map(arg -> solveAny(arg)))
                    }
                    case "eq" = {
                        checkArgc(mark, args, 2)
                        JLIRMetaVal.bool(solveAny(args[0]) == solveAny(args[1]))
                    }
                    case "java" = {
                        checkMinArgc(mark, args, 1)
                        val subcmd = getRawName(args[0])
                        switch subcmd {
                            case "callstatic"
                            case "callvirtual"
                            case "callinterface"
                            case "callspecial" = {
                                checkArgc(mark, args, 6)
                                val kind = subcmd["call".size():]
                                val returnType = solveAnyType(args[1])
                                val className = solveString(args[2])
                                val methodName = solveString(args[3])
                                val descriptor = solveString(args[4])
                                val irArgs = solveExprList(args[5])
                                JLIRMetaVal.expr(JLIRExpr(mark, returnType, JLIRExpr.Data.javacall(
                                    kind, className, methodName, descriptor, irArgs)))
                            }
                            case "getstatic" = {
                                checkArgc(mark, args, 5)
                                val returnType = solveAnyType(args[1])
                                val className = solveString(args[2])
                                val fieldName = solveString(args[3])
                                val descriptor = solveString(args[4])
                                JLIRMetaVal.expr(JLIRExpr(mark, returnType, JLIRExpr.Data.javagetstatic(
                                    className, fieldName, descriptor)))
                            }
                            case "setstatic" = {
                                checkArgc(mark, args, 6)
                                val returnType = solveAnyType(args[1])
                                val className = solveString(args[2])
                                val fieldName = solveString(args[3])
                                val descriptor = solveString(args[4])
                                val valexpr = solveExpr(args[5], null)
                                JLIRMetaVal.expr(JLIRExpr(mark, returnType, JLIRExpr.Data.javasetstatic(
                                    className, fieldName, descriptor, valexpr)))
                            }
                            case "getfield" = {
                                checkArgc(mark, args, 5)
                                val returnType = solveAnyType(args[1])
                                val className = solveString(args[2])
                                val fieldName = solveString(args[3])
                                val descriptor = solveString(args[4])
                                val owner = solveExpr(args[5], null)
                                JLIRMetaVal.expr(JLIRExpr(mark, returnType, JLIRExpr.Data.javagetfield(
                                    className, fieldName, descriptor, owner)))
                            }
                            case "setfield" = {
                                checkArgc(mark, args, 6)
                                val returnType = solveAnyType(args[1])
                                val className = solveString(args[2])
                                val fieldName = solveString(args[3])
                                val descriptor = solveString(args[4])
                                val owner = solveExpr(args[5], null)
                                val valexpr = solveExpr(args[6], null)
                                JLIRMetaVal.expr(JLIRExpr(mark, returnType, JLIRExpr.Data.javasetfield(
                                    className, fieldName, descriptor, owner, valexpr)))
                            }
                            case "new" = {
                                checkArgc(mark, args, 5)
                                val returnType = solveAnyType(args[1])
                                val className = solveString(args[2])
                                val descriptor = solveString(args[3])
                                val irArgs = solveExprList(args[4])
                                JLIRMetaVal.expr(JLIRExpr(mark, returnType, JLIRExpr.Data.javanew(
                                    className, descriptor, irArgs)))
                            }
                            else = throw JLError("Unrecognized java subcommand " + subcmd, [mark])
                        }
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

    private def checkMinArgc(mark: JLMark, args: List[JLAstMetaExpr], argc: Int) {
        if args.size() < argc {
            throw JLError("Expected at least " + argc + " args but got " + args.size(), [mark])
        }
    }

    private def getRawNameList(expr: JLAstMetaExpr): List[String] {
        getRawList(expr).map(e -> getRawName(e))
    }

    private def getRawList(expr: JLAstMetaExpr): List[JLAstMetaExpr] {
        val nullable = when expr.data {
            case apply(f, args) = switch f {
                case "list" = null(args)
                else = null
            }
            else = null
        }
        if null(args) = nullable {
            args
        } else {
            throw JLError("Expected raw list", [expr.mark])
        }
    }

    private def getRawName(expr: JLAstMetaExpr): String {
        when expr.data {
            case name(name) = name
            else = throw JLError("Expected raw name", [expr.mark])
        }
    }
}
