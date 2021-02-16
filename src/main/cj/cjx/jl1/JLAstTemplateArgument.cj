package cjx.jl1

import cjx.jl1.JLAstType
import cjx.jl1.JLMark

class JLAstTemplateArgument {
    union Data {
        # TODO: ConstIntExpr
        case int(Int)
        case type(JLAstType)
    }

    val mark: JLMark
    val data: Data
}
