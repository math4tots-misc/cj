package cj

native class Char: ToInt, ToChar, Hash, Repr {
    def toInt(self: Self): Int
    def toChar(self: Self): Char
    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
    def toString(self: Self): String
    def repr(self: Self): String

    ## The number of char codes this code point needs in the string encoding.
    ## 1 or 2 in UTF-16, and between 1 and 4 in UTF-8
    def size(self: Self): Int
}
