package cj

native class Char: ToInt, ToChar, Hash, Repr, Default, Ord {
    def toInt(self: Self): Int = js!(Int, self)
    def toChar(self: Self): Char = self
    def __eq(self: Self, other: Self): Bool = self is other
    def __lt(self, other: Self): Bool = js!(Bool, self, "<", other)
    def hash(self: Self): Int = toInt()
    def toString(self: Self): String = js!(String, "String.fromCodePoint(", self, ")")
    def repr(self: Self): String

    ## The number of char codes this code point needs in the string encoding.
    ## 1 or 2 in UTF-16, and between 1 and 4 in UTF-8
    def size(self: Self): Int = if toInt() < 0x10000 { 1 } else { 2 }

    ## Checks if the character is an ascii digit (0-9)
    def isDigit(self: Self): Bool = '0' <= self and self <= '9'

    ## Checks if the character is an ascii upper case letter (A-Z)
    def isUpper(self: Self): Bool = 'A' <= self and self <= 'Z'

    ## Checks if the character is an ascii lower case letter (a-z)
    def isLower(self: Self): Bool = 'a' <= self and self <= 'z'

    ## Checks if the character is an ascii letter (a-zA-Z)
    def isLetter(self: Self): Bool = isUpper() or isLower()

    ## Checks if the character is an ascii letter or digit (a-zA-Z0-9)
    def isLetterOrDigit(self: Self): Bool = isLetter() or isDigit()

    def default(): Char = '\0'
}
