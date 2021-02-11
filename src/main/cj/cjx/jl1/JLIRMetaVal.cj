package cjx.jl1

import cjx.jl1.JLIRExpr
import cjx.jl1.JLType

union JLIRMetaVal: Repr, Eq {
    case number(Double)
    case string(String)
    case list(List[JLIRMetaVal])
    case expr(JLIRExpr)
    case type(JLType)

    def bool(b: Bool): Self = number(if b { 1 } else { 0 })

    def repr(self): String = when self {
        case number(i) = "number(" + i.repr() + ")"
        case string(s) = "string(" + s.repr() + ")"
        case list(list) = list.repr()
        case expr(e) = "<expression>"
        case type(t) = "type(" + t + ")"
    }

    def __eq(self, other: Self): Bool = when self {
        case number(x) = when other { case number(y) = (x == y); else = false }
        case string(x) = when other { case string(y) = (x == y); else = false }
        case list(x) = when other { case list(y) = (x == y); else = false }
        case expr(x) = self is other
        case type(x) = when other { case type(y) = (x == y); else = false }
    }

    union Constraint {
        case any
        case anyType
        case anyExpr
        case expr(JLType)
        case truthy
    }
}
