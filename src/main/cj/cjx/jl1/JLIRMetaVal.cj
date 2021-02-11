package cjx.jl1

import cjx.jl1.JLError
import cjx.jl1.JLMark
import cjx.jl1.JLAstMetaExpr
import cjx.jl1.JLIRExpr
import cjx.jl1.JLType

union JLIRMetaVal: Repr, Eq, Default {
    case number(Double)
    case string(String)
    case list(List[JLIRMetaVal])
    case expr(JLIRExpr)
    case type(JLType)
    case lambda(Scope, List[String], List[JLAstMetaExpr])

    def bool(b: Bool): Self = number(if b { 1 } else { 0 })

    def repr(self): String = when self {
        case number(i) = "number(" + i.repr() + ")"
        case string(s) = "string(" + s.repr() + ")"
        case list(list) = list.repr()
        case expr(e) = "<expression>"
        case type(t) = "type(" + t + ")"
        case lambda(scope, argnames, body) = "lambda(" + ",".join(argnames) + ")"
    }

    def __eq(self, other: Self): Bool = when self {
        case number(x) = when other { case number(y) = (x == y); else = false }
        case string(x) = when other { case string(y) = (x == y); else = false }
        case list(x) = when other { case list(y) = (x == y); else = false }
        case expr(x) = self is other
        case type(x) = when other { case type(y) = (x == y); else = false }
        case lambda(s, x, y) = self is other
    }

    def default(): Self = number(0)

    union Constraint {
        case any
        case anyType
        case anyExpr
        case expr(JLType)
        case truthy
    }

    @derive(new, repr)
    class Scope {
        val parent: Nullable[Scope]
        val locals: Map[String, JLIRMetaVal] = Map()

        def getOrNull(self, name: String): Nullable[JLIRMetaVal] {
            if null(v) = locals.getOrNull(name) {
                null(v)
            } else if null(p) = parent {
                p.getOrNull(name)
            } else {
                null
            }
        }

        def get(self, mark: JLMark, name: String): JLIRMetaVal {
            if null(v) = getOrNull(name) {
                v
            } else {
                throw JLError("Meta variable " + name + " not found", [mark])
            }
        }

        def __setitem(self, name: String, v: JLIRMetaVal) {
            locals[name] = v
        }
    }
}
