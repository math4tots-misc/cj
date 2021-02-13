package cjx.jl3

import cjx.jl3.J3Expr
import cjx.jl3.J3Type
import cjx.jl3.J3Local
import cjx.jl1.JLMark

class J3Method {
    val mark: JLMark
    val modifiers: List[String]
    val name: String
    val parameters: List[J3Local]
    val returnType: J3Type
    val body: Nullable[J3Expr] = null

    def isStatic(self): Bool = "static" in modifiers
}
