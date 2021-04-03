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
    def __eq(self, other: Self): Bool = tag!(self) == tag!(other)
}
