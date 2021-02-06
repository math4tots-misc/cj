package cjx.jl1

import cjx.jl1.JLMark

## Type expression
@derive(new)
class JLAstType {
    val mark: JLMark
    val name: String
    val args: List[JLAstType]
}
