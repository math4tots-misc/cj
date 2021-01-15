package cj

native class Char: ToInt {
    def toInt(self: Self): Int
    def toChar(self: Self): Char

    ## The number of char codes this code point needs in the string encoding.
    ## 1 or 2 in UTF-16, and between 1 and 4 in UTF-8
    def size(self: Self): Int
}
