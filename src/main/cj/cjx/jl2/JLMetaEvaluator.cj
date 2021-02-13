package cjx.jl2

import cj.Math
import cjx.jl1.JLMark
import cjx.jl1.JLError
import cjx.jl2.JLMetaVal
import cjx.jl2.JLMetaExpr
import cjx.jl2.JLMetaScope

@derive(new)
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
                    case "var"
                    case "val" = {
                        val mutable = form == "var"
                        if argexprs and argexprs[0].isApply() {
                            val names = getRawNameList(argexprs[0])
                            val functionName = names[0]
                            val argnames = names[1:]
                            val body = if argexprs.size() == 2 { argexprs[1] } else {
                                JLMetaExpr(mark, JLMetaExpr.Data.apply("begin", argexprs[1:]))
                            }
                            val lambda = JLMetaVal.lambda(mark, scope, argnames, null, body)
                            declvar(mark, functionName, lambda, mutable)
                            JLMetaVal.nil()
                        } else {
                            _checkArgc(mark, 2, argexprs.size())
                            val name = getRawName(argexprs[0])
                            val value = eval(argexprs[1])
                            declvar(mark, name, value, mutable)
                            JLMetaVal.nil()
                        }
                    }
                    case "set" = {
                        _checkArgc(mark, 2, argexprs.size())
                        val name = getRawName(argexprs[0])
                        setvar(mark, name, eval(argexprs[1]))
                        Default()
                    }
                    case "while" = {
                        _checkMinArgc(mark, 1, argexprs.size())
                        while eval(argexprs[0]) {
                            for i = 1; i < argexprs.size(); i++ {
                                eval(argexprs[i])
                            }
                        }
                        JLMetaVal.nil()
                    }
                    case "begin" = {
                        var last = JLMetaVal.nil()
                        for argexpr in argexprs {
                            last = eval(argexpr)
                        }
                        last
                    }
                    case "module"
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
                        _checkMinArgc(mark, 1, argexprs.size())
                        val argnames = getRawNameList(argexprs[0])
                        val body = if argexprs.size() == 2 { argexprs[1] } else {
                            JLMetaExpr(mark, JLMetaExpr.Data.apply("begin", argexprs[1:]))
                        }
                        JLMetaVal.lambda(mark, scope, argnames, null, body)
                    }
                    case "call" = {
                        _checkMinArgc(mark, 1, argexprs.size())
                        val function = eval(argexprs[0])
                        val args = argexprs[1:].map(e -> eval(e))
                        _call(mark, function, args)
                    }
                    else = {
                        val f = getvar(mark, form)
                        val args = argexprs.map(e -> eval(e))
                        _call(mark, f, args)
                    }
                }
            }
        }
    }

    def evalInt(self, expr: JLMetaExpr): Int {
        when eval(expr) {
            case number(x) = x.toInt()
            else = throw JLError("Expected a number", [expr.mark])
        }
    }

    def _call(self, mark: JLMark, function: JLMetaVal, args: List[JLMetaVal]): JLMetaVal {
        when function {
            case builtin(f) = f.call(self, args)
            case lambda(lmark, lscope, argnames, vararg, body) = {
                val oldScope = scope
                scope = JLMetaScope(null(lscope))
                var i = 0
                val limit = Math.min(args.size(), argnames.size())
                for ; i < limit; i++ {
                    declvar(lmark, argnames[i], args[i], true)
                }
                for ; i < argnames.size(); i++ {
                    declvar(lmark, argnames[i], JLMetaVal.nil(), true)
                }
                if null(va) = vararg {
                    val list = args[i:]
                    declvar(lmark, va, JLMetaVal.list(list), true)
                }
                val result = eval(body)
                scope = oldScope
                result
            }
            else = throw JLError(function.repr() + " is not callable", [mark])
        }
    }

    def checkArgc(self, expected: Int, actual: Int) {
        if expected != actual {
            throw err("Expected " + expected + " args but got " + actual)
        }
    }

    def _checkArgc(self, mark: JLMark, expected: Int, actual: Int) {
        if expected != actual {
            throw _err(mark, "Expected " + expected + " args but got " + actual)
        }
    }

    def _checkMinArgc(self, mark: JLMark, expected: Int, actual: Int) {
        if actual < expected {
            throw _err(mark, "Expected at least " + expected + " args but got " + actual)
        }
    }

    def getRawName(self, expr: JLMetaExpr): String {
        when expr.data {
            case name(name) = name
            else = throw _err(expr.mark, "Expected raw name")
        }
    }

    def getRawNameList(self, expr: JLMetaExpr): List[String] {
        when expr.data {
            case literal(value) = when value {
                case nil = []
                else = throw _err(expr.mark, "Expected raw name list")
            }
            case apply(form, args) = {
                val names = [form]
                for arg in args {
                    names.add(getRawName(arg))
                }
                names
            }
            else = throw _err(expr.mark, "Expected raw name list")
        }
    }

    private def _err(self, mark: JLMark, message: String): JLError = {
        markStack.add(mark)
        JLError(message, markStack)
    }

    def err(self, message: String): JLError = {
        JLError(message, markStack)
    }

    def getvar(self, mark: JLMark, name: String): JLMetaVal {
        if null(value) = scope.getOrNull(name) {
            value
        } else {
            throw _err(mark, "Meta variable " + name + " not found")
        }
    }

    def setvar(self, mark: JLMark, name: String, value: JLMetaVal) {
        if null(message) = scope.setOrMessage(name, value) {
            throw _err(mark, message)
        }
    }

    def declvar(self, mark: JLMark, name: String, value: JLMetaVal, mutable: Bool) {
        if null(message) = scope.declareOrMessage(name, value, mutable) {
            throw _err(mark, message)
        }
    }
}
