package cj

native class Double: Repr, Hash {
    def repr(self: Self): String
    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
}