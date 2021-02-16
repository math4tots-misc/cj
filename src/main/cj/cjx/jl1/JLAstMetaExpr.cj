package cjx.jl1

import cjx.jl1.JLAstExpr
import cjx.jl1.JLAstType
import cjx.jl1.JLIRMetaVal
import cjx.jl1.JLMark

class JLAstMetaExpr {
    union Data {
        case value(JLIRMetaVal)
        case type(JLAstType)
        case expr(JLAstExpr)
        case name(String)
        case apply(String, List[JLAstMetaExpr])
    }

    val mark: JLMark
    val data: Data
}
