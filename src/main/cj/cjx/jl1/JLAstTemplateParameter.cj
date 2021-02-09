package cjx.jl1

import cjx.jl1.JLAstType
import cjx.jl1.JLMark

@derive(new)
class JLAstTemplateParameter {
    union Kind {
        case int
        case type
    }

    val mark: JLMark
    val modifiers: List[String]
    val name: String
    val kind: Kind
}
