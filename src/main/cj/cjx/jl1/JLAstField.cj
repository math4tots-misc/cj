package cjx.jl1

import cjx.jl1.JLAstExpr
import cjx.jl1.JLAstType
import cjx.jl1.JLMark

class JLAstField {
    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val name: String
    val type: Nullable[JLAstType]
    val init: Nullable[JLAstExpr]

    def isStatic(self): Bool = "static" in modifiers
}
