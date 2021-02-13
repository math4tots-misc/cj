package cjx.jl1

import cjx.jl1.JLAstMetaExpr
import cjx.jl1.JLAstTemplateParameter
import cjx.jl1.JLAstType
import cjx.jl1.JLAstMethod
import cjx.jl1.JLAstField
import cjx.jl1.JLMark

@derive(new)
class JLAstClass {

    union Kind {
        case class_
        case union_
        case trait_
        case interface_
    }

    union Member {
        case klass(JLAstClass)
        case case_(String, List[JLAstType])
        case field(JLAstField)
        case method(JLAstMethod)
        case conditional(JLAstMetaExpr, List[Member])
    }

    union DirectMember {
        case field(JLAstField)
        case method(JLAstMethod)
    }

    val mark: JLMark
    val comment: Nullable[String]
    val modifiers: List[String]
    val kind: Kind
    val shortName: String
    val templateParameters: List[JLAstTemplateParameter]
    val bases: List[JLAstType]
    val members: List[Member]

    def isUnion(self): Bool = when kind { case union_ = true; else = false }
    def isTrait(self): Bool = when kind { case trait_ = true; else = false }
    def isInterface(self): Bool = when kind { case interface_ = true; else = false }

    def isNative(self): Bool = "native" in modifiers

    def __get_fields(self): List[JLAstField] = {
        members.flatMap(mem -> when mem {
            case field(f) = [f]
            else = []
        })
    }
}
