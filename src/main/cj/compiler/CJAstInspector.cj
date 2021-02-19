package compiler

import compiler.CJItemKind
import cj.StringBuilder
import compiler.CJAst
import compiler.CJAst.Expr

class CJAstInspector {
    val sb: StringBuilder = Default()
    var depth = 0
    var showExprs = false

    private def line(self, line: String) {
        sb.add("  " * depth + line + "\n")
    }

    private def nest(self, f: Fn[Unit]) {
        depth = depth + 1
        f.call()
        depth = depth - 1
    }

    def inspectFile(file: CJAst.File): String {
        val self = Self()
        self._inspectFile(file)
        self.sb.toString()
    }

    def _inspectFile(self, file: CJAst.File) {
        line(file.packageName + "." + file.item.shortName)
        nest(() -> {
            line("package " + file.packageName)
            for imp in file.imports {
                line("import " + imp.fullName + " (" + imp.alias + ")")
            }
            _inspectItem(file.item)
        })
    }

    def _type(t: CJAst.Type): String {
        if t.args {
            t.name + "[" + ", ".join(t.args.map(arg -> _type(arg))) + "]"
        } else {
            t.name
        }
    }
    def _ntype(nt: Nullable[CJAst.Type]): String = if val t = nt { _type(t) } else { "null" }
    def _ltype(lt: List[CJAst.Type]): String = "[" + ", ".join(lt.map(t -> _type(t))) + "]"

    def _itemkind(itemKind: CJItemKind): String = when itemKind {
        case class_ = "class"
        case union_ = "union"
        case trait_ = "trait"
    }

    def _inspectItem(self, item: CJAst.Item) {
        line(_itemkind(item.kind) + " " + item.shortName)
        nest(() -> {
            for member in item.members {
                _inspectMember(member)
            }
        })
    }

    def _inspectMember(self, member: CJAst.Member) {
        when member {
            case item(item) = _inspectItem(item)
            case field(field) = _inspectField(field)
            case case_(case_) = _inspectCase(case_)
            case method(method) = _inspectMethod(method)
        }
    }

    def _inspectField(self, field: CJAst.Field) {
        val lead = if field.mutable { "var " } else { "val " }
        line(lead + field.name + if val t = field.type { ": " + _type(t) } else { "" })
        if val init = field.init {
            nest(() -> _inspectExprTop("init", init))
        }
    }

    def _inspectCase(self, case_: CJAst.Case) {
        if case_.types {
            line("case " + case_.name + "(" + ", ".join(case_.types.map(t -> _type(t))) + ")")
        } else {
            line("case " + case_.name)
        }
    }

    def _inspectExprTop(self, header: String, expr: CJAst.Expr) {
        if showExprs {
            if val s = _expr0(expr) {
                line(header + " " + s)
            } else {
                line(header + ":")
                nest(() -> _inspectExpr(expr))
            }
        } else {
            line(header + " (expr)")
        }
    }

    def _inspectMethod(self, method: CJAst.Method) {
        val params = ", ".join(method.parameters.map(p -> _local(p)))
        line("method " + method.name + "(" + params + ")")
        nest(() -> {
            if val body = method.body {
                _inspectExprTop("body", body)
            }
        })
    }

    private def _local(local: CJAst.Local): String {
        if val type = local.type {
            local.name + ": " + _type(type)
        } else { local.name }
    }

    ## Tries to display the contents of the expression in a small string
    ## if it can
    private def _expr0(expr: Expr): String? {
        null(when expr.data {
            case unit = "()"
            case bool(x) = x.repr()
            case char(x) = x.repr()
            case int(x) = x.repr()
            case double(x) = x.repr()
            case string(x) = x.repr()
            case bigint(x) = x.repr()
            case call(nt, methodName, typeArgs, args) {
                val argstrs = List[String]()
                for arg in args {
                    if val argstr = _expr0(arg) { argstrs.add(argstr) } else { return null }
                }
                val typestrs = "[" + ", ".join(typeArgs.map(t -> _type(t))) + "]"
                val owner = if val (t) = nt { _type(t) } else { "null" }
                "call(" + owner + ", " + typestrs + ", [" + ", ".join(argstrs) + "])"
            }
            case callname(methodName, typeArgs, args) {
                val argstrs = List[String]()
                for arg in args {
                    if val argstr = _expr0(arg) { argstrs.add(argstr) } else { return null }
                }
                val typestrs = "[" + ", ".join(typeArgs.map(t -> _type(t))) + "]"
                "callname(" + typestrs + ", [" + ", ".join(argstrs) + "])"
            }
            else = return null
        })
    }

    def _inspectExpr(self, expr: CJAst.Expr) {
        if val s = _expr0(expr) {
            line(s)
        } else {
            when expr.data {
                case block(subexprs) {
                    line("block")
                    nest(() -> {
                        for subexpr in subexprs {
                            _inspectExpr(subexpr)
                        }
                    })
                }
                case call(nt, methodName, typeArgs, args) {
                    line("method " + methodName + if val t = nt { " " + _type(t) } else { "" })
                    nest(() -> {
                        for arg in args {
                            _inspectExpr(arg)
                        }
                    })
                }
                else = line("<unrecognized>")
            }
        }
    }
}
