package cjx.jl1

import cjx.jl1.JLMark
import cjx.jl1.JLType

class JLIRField {
    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val name: String
    val type: JLType

    def isStatic(self): Bool = "static" in modifiers
    def isMutable(self): Bool = "var" in modifiers
}
