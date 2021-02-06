package cjx.jl1

import cjx.jl1.JLType
import cjx.jl1.JLMark

## Local variable declaration
@derive(new)
class JLAstLocal {
    val mark: JLMark
    val name: String
    val type: JLType
}
