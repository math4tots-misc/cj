package cj

native class String: Repr, ToBool {
    def toString(self: Self): Self
    def repr(self: Self): String

    def __add[T: ToString](self: Self, other: T): Self
    def size(self: Self): Int

    def toBool(self: Self): Bool
}
