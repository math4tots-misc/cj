package cjx.jl3

import cjx.jl3.J3AstType
import cjx.jl3.J3AstMetaExpr
import cjx.jl3.J3Mark

class J3AstItem {

    union Kind {
        case class_
        case trait_
    }

    union Member {
        case block(List[Member])
        case base(J3AstType)
        case if_(J3AstMetaExpr, Member)
    }

    val mark: J3Mark
    val modifiers: List[String]
    val kind: Kind
    val shortName: String
    val members: List[Member]
}
