package cjx.jl1

import cjx.jl1.JLAstType
import cjx.jl1.JLAstExpr
import cjx.jl1.JLMark

## Local variable declaration
class JLAstLocal {
    val mark: JLMark
    val modifiers: List[String]
    val name: String
    val type: Nullable[JLAstType]
    val init: Nullable[JLAstExpr]
}
