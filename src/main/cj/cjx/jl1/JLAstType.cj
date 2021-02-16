package cjx.jl1

import cjx.jl1.JLAstTemplateArgument
import cjx.jl1.JLMark

## Type expression
class JLAstType {

    union Data {
        case noreturn
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
        case klass(String, List[JLAstTemplateArgument])
    }

    val mark: JLMark
    val data: Data
}
