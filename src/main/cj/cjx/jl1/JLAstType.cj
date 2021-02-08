package cjx.jl1

import cjx.jl1.JLMark

## Type expression
@derive(new)
class JLAstType {

    union Data {
        case void
        case bool
        case byte
        case char
        case short
        case int
        case long
        case float
        case double
        case array(JLAstType)
        case klass(String, List[JLAstType])
    }

    val mark: JLMark
    val data: Data
}
