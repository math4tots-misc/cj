package compiler

@derive(repr)
union CJItemKind {
    case class_
    case union_
    case trait_
    def toString(self): String = when self {
        case class_ = "class"
        case union_ = "union"
        case trait_ = "trait"
    }
}
