package compiler

@derive(repr)
union CJItemKind {
    case class_
    case union_
    case trait_
}
