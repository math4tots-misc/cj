package cjx.jl1

import cjx.jl1.JLAstType
import cjx.jl1.JLMark

@derive(new)
class JLAstField {
    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val name: String
    val type: JLAstType
}
