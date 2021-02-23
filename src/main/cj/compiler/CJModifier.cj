package compiler

union CJModifier: Eq {
    case native_
    case static_
    case public_
    case private_
    case async_
    def __eq(self, other: Self): Bool = when self {
        case native_ = when other { case native_ = true; else = false }
        case static_ = when other { case static_ = true; else = false }
        case public_ = when other { case public_ = true; else = false }
        case private_ = when other { case private_ = true; else = false }
        case async_ = when other { case async_ = true; else = false }
    }
}
