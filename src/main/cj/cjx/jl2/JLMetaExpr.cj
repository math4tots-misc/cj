package cjx.jl2

import cjx.jl2.JLMetaVal
import cjx.jl1.JLMark

@derive(new)
class JLMetaExpr {
    union Data {
        case literal(JLMetaVal)
        case name(String)
        case apply(String, List[JLMetaExpr])
    }
    val mark: JLMark
    val data: Data
}
