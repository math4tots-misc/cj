package cjx.jl1

import cjx.jl1.JLType

union JLIRTemplateArgument: Repr {
    case int(Int)
    case type(JLType)

    def repr(self): String = when self {
        case int(i) = "" + i
        case type(t) = "" + t
    }
}
