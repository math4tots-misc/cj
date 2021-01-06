package cj

native class String: Repr, ToBool, Hash {
    def toString(self: Self): Self
    def repr(self: Self): String

    def __add[T: ToString](self: Self, other: T): Self
    def size(self: Self): Int

    def toBool(self: Self): Bool

    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
}
