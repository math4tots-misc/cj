package cj

native class String: Repr, ToBool, Hash, Ord, Iterable[Char], Default {
    def toString(self: Self): Self
    def repr(self: Self): String

    def __add[T?: ToString](self: Self, other: T): Self

    ## Number of char codes in this string.
    ## NOTE: If the default encoding is UTF-16, this is neither the number of bytes
    ## nor the number of code points.
    def size(self: Self): Int

    def toBool(self: Self): Bool

    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
    def __lt(self, other: Self): Bool

    def __contains(self, other: Self): Bool

    def join[T?: ToString, C?: Iterable[T]](self: Self, parts: C): String

    def charCodeAt(self: Self, i: Int): Int
    def charAt(self: Self, i: Int): Char
    def iter(self: Self): Iterator[Char]

    def __slice(self: Self, start: Int, end: Int): String
    def __sliceFrom(self: Self, start: Int): String
    def __sliceTo(self: Self, end: Int): String

    def __mul(self, n: Int): String

    ## Return a new string repeatedly padded with the given prefix until the
    ## final length is at least as long as length
    def lpad(self, length: Int, prefix: String): String

    ## Return a new string repeatedly padded with the given suffix until the
    ## final length is at least as long as length
    def rpad(self, length: Int, suffix: String): String

    def parseInt(self: Self): Nullable[Int]
    def parseDouble(self: Self): Nullable[Double]

    def startsWith(self, prefix: String): Bool
    def startsWithAt(self, prefix: String, startIndex: Int): Bool
    def endsWith(self, suffix: String): Bool
    def endsWithAt(self, suffix: String, endIndex: Int): Bool

    def trim(self: Self): String
    def lower(self): String
    def upper(self): String
    def replace(self, old: String, new: String): String

    ## Return -1 if not found
    def indexOf(self, substring: String): Int

    def default(): Self
}
