package cjx.jl2

import cjx.jl1.JLMark
import cjx.jl2.JLMetaEvaluator
import cjx.jl2.JLMetaExpr
import cjx.jl2.JLMetaScope

union JLMetaVal: Eq, Repr, Default, ToBool {
    case nil
    case bool(Bool)
    case number(Double)
    case string(String)
    case list(List[JLMetaVal])
    case lambda(JLMark, JLMetaScope, List[String], Nullable[String], JLMetaExpr)
    case builtin(Fn[JLMetaEvaluator, List[JLMetaVal], JLMetaVal])

    def default(): Self = nil()

    def toBool(self): Bool = when self {
        case nil = false
        case bool(b) = b
        case number(x) = x != 0
        case string(s) = s.size() != 0
        case list(list) = list.size() != 0
        case lambda(m, s, a, v, b) = true
        case builtin(f) = true
    }

    def __eq(self, other: Self): Bool {
        when self {
            case nil = when other { case nil = true; else = false }
            case bool(x) = when other { case bool(y) = x == y; else = false }
            case number(x) = when other { case number(y) = x == y; else = false }
            case list(x) = when other { case list(y) = x == y; else = false }
            case string(x) = when other { case string(y) = x == y; else = false }
            case lambda(a, b, c, d, e) = self is other
            case builtin(f) = self is other
        }
    }

    def toString(self): String = when self {
        case string(s) = s
        else = repr()
    }

    def repr(self): String = when self {
        case nil = "nil"
        case bool(b) = if b { "true" } else { "false" }
        case number(x) = x.repr()
        case list(list) = list.repr()
        case string(s) = s.repr()
        case lambda(mark, scope, argnames, variadic, body) = "<lambda>"
        case builtin(f) = "<builtin>"
    }
}
