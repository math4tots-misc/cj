package cj

native class Bool: ToBool, Repr {
    def toBool(self: Self): Self
    def repr(self: Self): String
}
