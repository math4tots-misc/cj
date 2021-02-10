package cjx.jl1

import cjx.jl1.JLAstType
import cjx.jl1.JLMark

@derive(new)
class JLAstTemplateArgument {
    union Data {
        case int(Int)
        case type(JLAstType)
    }

    val mark: JLMark
    val data: Data
}
