package cjx.jl1

import cjx.jl1.JLMark
import cjx.jl1.JLType

@derive(new)
class JLIRField {
    val mark: JLMark
    val modifiers: List[String]
    val name: String
    val type: JLType

    def isStatic(self): Bool = "static" in modifiers
}
