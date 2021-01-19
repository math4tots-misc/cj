package cj

native class String: Repr, ToBool, Hash, Iterable[Char] {
    def toString(self: Self): Self
    def repr(self: Self): String

    def __add[T: ToString](self: Self, other: T): Self

    ## Number of char codes in this string.
    ## NOTE: If the default encoding is UTF-16, this is neither the number of bytes
    ## nor the number of code points.
    def size(self: Self): Int

    def toBool(self: Self): Bool

    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int

    def join[T: ToString, C: Iterable[T]](self: Self, parts: C): String

    def charCodeAt(self: Self, i: Int): Int
    def charAt(self: Self, i: Int): Char
    def iter(self: Self): Iterator[Char]

    def __slice(self: Self, start: Int, end: Int): String
    def __sliceFrom(self: Self, start: Int): String
    def __sliceTo(self: Self, end: Int): String

    def parseInt(self: Self): Nullable[Int]
}
