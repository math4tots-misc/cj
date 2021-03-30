package compiler

union CJModifier: Eq {
    case native_
    case static_
    case public_
    case private_
    case async_
    case synthetic
    def __eq(self, other: Self): Bool = tag!(self) is tag!(other)
}
