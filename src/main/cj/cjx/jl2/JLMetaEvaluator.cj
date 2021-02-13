package cjx.jl2

import cjx.jl1.JLMark
import cjx.jl1.JLError
import cjx.jl2.JLMetaVal
import cjx.jl2.JLMetaExpr
import cjx.jl2.JLMetaScope

class JLMetaEvaluator {
    var scope: JLMetaScope
    val markStack: List[JLMark] = []

    def eval(self, expr: JLMetaExpr): JLMetaVal {
        when expr.data {
            case literal(value) = value
            case name(name) = getvar(expr.mark, name)
            case apply(form, argexprs) = {
                val mark = expr.mark
                switch form {
                    case "val" = {
                        checkArgc(mark, 2, argexprs.size())
                        val name = getRawName(argexprs[0])
                        val value = eval(argexprs[1])
                        declvar(mark, name, value, false)
                        JLMetaVal.nil()
                    }
                    case "var" = {
                        checkArgc(mark, 2, argexprs.size())
                        val name = getRawName(argexprs[0])
                        val value = eval(argexprs[1])
                        declvar(mark, name, value, true)
                        JLMetaVal.nil()
                    }
                    case "begin" = {
                        var last = JLMetaVal.nil()
                        for argexpr in argexprs {
                            last = eval(argexpr)
                        }
                        last
                    }
                    case "scope" = {
                        val oldScope = scope
                        scope = JLMetaScope(null(oldScope))
                        var last = JLMetaVal.nil()
                        for argexpr in argexprs {
                            last = eval(argexpr)
                        }
                        scope = oldScope
                        last
                    }
                    case "list" = JLMetaVal.list(argexprs.map(e -> eval(e)))
                    case "lambda" = {
                        checkMinArgc(mark, 1, argexprs.size())
                        val argnames = getRawNameList(argexprs[0])
                        val body = if argexprs.size() == 2 { argexprs[1] } else {
                            JLMetaExpr(mark, JLMetaExpr.Data.apply("begin", argexprs[1:]))
                        }
                        JLMetaVal.lambda(scope, argnames, null, body)
                    }
                    else = throw JLError("Unrecognized form " + form.repr(), [mark])
                }
            }
        }
    }

    def checkArgc(self, mark: JLMark, expected: Int, actual: Int) {
        if expected != actual {
            throw err(mark, "Expected " + expected + " args but got " + actual)
        }
    }

    def checkMinArgc(self, mark: JLMark, expected: Int, actual: Int) {
        if expected < actual {
            throw err(mark, "Expected at least " + expected + " args but got " + actual)
        }
    }

    def getRawName(self, expr: JLMetaExpr): String {
        when expr.data {
            case name(name) = name
            else = throw err(expr.mark, "Expected raw name")
        }
    }

    def getRawNameList(self, expr: JLMetaExpr): List[String] {
        when expr.data {
            case apply(form, args) = {
                if form == "list" {
                    args.map(arg -> getRawName(arg))
                } else {
                    throw err(expr.mark, "Expected raw name list")
                }
            }
            else = throw err(expr.mark, "Expected raw name list")
        }
    }

    private def err(self, mark: JLMark, message: String): JLError = {
        markStack.add(mark)
        JLError(message, markStack)
    }

    def getvar(self, mark: JLMark, name: String): JLMetaVal {
        if null(value) = scope.getOrNull(name) {
            value
        } else {
            throw err(mark, "Meta variable " + name + " not found")
        }
    }

    def setvar(self, mark: JLMark, name: String, value: JLMetaVal) {
        if null(message) = scope.setOrMessage(name, value) {
            throw err(mark, message)
        }
    }

    def declvar(self, mark: JLMark, name: String, value: JLMetaVal, mutable: Bool) {
        if null(message) = scope.declareOrMessage(name, value, mutable) {
            throw err(mark, message)
        }
    }
}
