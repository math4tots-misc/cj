package cjx.jl1

import cjx.jl1.JLType
import cjx.jl1.JLMark

@derive(new)
class JLIRLocal {
    val mark: JLMark
    val index: Int
    val name: String
    val type: JLType
}
