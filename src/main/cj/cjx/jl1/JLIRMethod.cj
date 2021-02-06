package cjx.jl1

import cjx.jl1.JLMark
import cjx.jl1.JLIRExpr
import cjx.jl1.JLIRLocal
import cjx.jl1.JLType

@derive(new)
class JLIRMethod {
    val mark: JLMark
    val modifiers: List[String]
    val localThis: Nullable[JLIRLocal]
    val name: String
    val parameters: List[JLIRLocal]
    val returnType: JLType
    var body: Nullable[JLIRExpr] = null

    def isStatic(self): Bool = localThis.isEmpty()
}
