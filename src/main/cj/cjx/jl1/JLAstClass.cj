package cjx.jl1

import cjx.jl1.JLAstTemplateParameter
import cjx.jl1.JLAstType
import cjx.jl1.JLAstMethod
import cjx.jl1.JLAstField
import cjx.jl1.JLMark

@derive(new)
class JLAstClass {
    union Member {
        case klass(JLAstClass)
        case field(JLAstField)
        case method(JLAstMethod)
    }

    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val _isInterface: Bool
    val shortName: String
    val templateParameters: List[JLAstTemplateParameter]
    val interfaces: List[JLAstType]
    val members: List[Member]

    def isInterface(self): Bool = _isInterface
}
