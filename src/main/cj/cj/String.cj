package cj

native class String: Repr {
    def toString(self: Self): Self
    def repr(self: Self): String

    def __add[T: ToString](self: Self, other: T): Self
    def size(self: Self): Int
}
