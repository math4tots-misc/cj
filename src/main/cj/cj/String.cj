package cj

native class String: ToString {
    def toString(self: Self): Self
    def __add[T: ToString](self: Self, other: T): Self
    def size(self: Self): Int
}
