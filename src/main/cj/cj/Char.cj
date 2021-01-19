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

    ## Checks if the character is an ascii digit (0-9)
    def isDigit(self: Self): Bool

    ## Checks if the character is an ascii upper case letter (A-Z)
    def isUpper(self: Self): Bool

    ## Checks if the character is an ascii lower case letter (a-z)
    def isLower(self: Self): Bool

    ## Checks if the character is an ascii letter (a-zA-Z0-9)
    def isLetter(self: Self): Bool

    ## Checks if the character is an ascii letter or digit (a-zA-Z0-9)
    def isLetterOrDigit(self: Self): Bool
}
