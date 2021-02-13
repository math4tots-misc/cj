package cjx.jl2

import cjx.jl2.JLMetaExpr
import cjx.jl2.JLMetaScope

union JLMetaVal: Eq, Repr {
    case nil
    case bool(Bool)
    case number(Double)
    case list(List[JLMetaVal])
    case lambda(JLMetaScope, List[String], Nullable[String], JLMetaExpr)

    def __eq(self, other: Self): Bool {
        when self {
            case nil = when other { case nil = true; else = false }
            case bool(x) = when other { case bool(y) = x == y; else = false }
            case number(x) = when other { case number(y) = x == y; else = false }
            case list(x) = when other { case list(y) = x == y; else = false }
            case lambda(a, b, c, d) = self is other
        }
    }

    def repr(self): String = when self {
        case nil = "nil"
        case bool(b) = if b { "true" } else { "false" }
        case number(x) = x.repr()
        case list(list) = list.repr()
        case lambda(scope, argnames, variadic, body) = "<lambda>"
    }
}
