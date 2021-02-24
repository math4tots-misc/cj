package compiler

@derive(repr)
union CJItemKind: Eq {
    case class_
    case union_
    case trait_
    def toString(self): String = when self {
        case class_ = "class"
        case union_ = "union"
        case trait_ = "trait"
    }
    def __eq(self, other: Self): Bool = when self {
        case class_ = when other { case class_ = true; else = false }
        case union_ = when other { case union_ = true; else = false }
        case trait_ = when other { case trait_ = true; else = false }
    }
}
