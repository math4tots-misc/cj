package cjx.jl1

import cjx.jl1.JLAstType
import cjx.jl1.JLMark

@derive(new)
class JLAstExpr {
    union Data {
        case boolean(Bool)
        case int(Int)
        case double(Double)
        case string(String)
        case block(List[JLAstExpr])
        case callstatic(JLAstType, String, List[JLAstExpr])
        case callinstance(JLAstExpr, String, List[JLAstExpr])
        case getstatic(JLAstType, String)
        case setstatic(JLAstType, String, JLAstExpr)
    }

    val mark: JLMark
    val data: Data
}
