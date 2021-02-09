package cjx.jl1

import cjx.jl1.JLType

union JLIRTemplateArgument {
    case int(Int)
    case type(JLType)
}
