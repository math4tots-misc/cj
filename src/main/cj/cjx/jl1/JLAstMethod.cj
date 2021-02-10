package cjx.jl1

import cjx.jl1.JLAstTemplateParameter
import cjx.jl1.JLAstExpr
import cjx.jl1.JLAstType
import cjx.jl1.JLAstLocal
import cjx.jl1.JLMark

@derive(new)
class JLAstMethod {
    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val name: String
    val templateParameters: List[JLAstTemplateParameter]
    val parameters: List[JLAstLocal]
    val returnType: JLAstType
    val body: Nullable[JLAstExpr]

    def isStatic(self): Bool = "static" in modifiers
}
