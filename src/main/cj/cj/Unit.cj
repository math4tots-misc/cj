package cj

native class Unit : Hash, Repr {
    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
    def repr(self: Self): String
}
