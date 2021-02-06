package cjx.jl1

import cjx.jl1.JLAstType
import cjx.jl1.JLAstLocal
import cjx.jl1.JLMark

@derive(new)
class JLAstMethod {
    val mark: JLMark
    val modifiers: List[String]
    val name: String
    val parameters: List[JLAstLocal]
    val returnType: JLAstType

    def isStatic(self): Bool = "static" in modifiers
}
