package cj

native class Bool: ToBool, Repr, Hash {
    def toBool(self: Self): Self
    def repr(self: Self): String
    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
}
