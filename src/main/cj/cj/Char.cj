package cj

import cj.Error
import cj.StringBuilder

## A proper unicode codepoint.
##
## NOTE: the ".size()" of a string does not always equal the number of Chars in that string.
## This is because some Chars may require more than one char codes in the string.
## You can use the '.size()' method on a Char to determine how much this should be.
##
native class Char: ToInt, ToChar, Hash, Repr, Default, Ord {
    def toInt(self: Self): Int = js!(Int, self)
    def toChar(self: Self): Char = self
    def __eq(self: Self, other: Self): Bool = self is other
    def __lt(self, other: Self): Bool = js!(Bool, self, "<", other)
    def hash(self: Self): Int = toInt()
    def toString(self: Self): String = js!(String, "String.fromCodePoint(", self, ")")

    def repr(self: Self): String {
        val sb = StringBuilder()
        sb.char('\'')
        switch self {
            case '\0' = sb.str("\\0")
            case '\n' = sb.str("\\n")
            case '\r' = sb.str("\\r")
            case '\t' = sb.str("\\t")
            case '"' = sb.str("\\\"")
            case '\'' = sb.str("\\\'")
            else {
                if self.toInt() < 32 {
                    sb.str("\\x" + self.toInt().hex().lpad(2, "0"))
                } else if self.toInt() >= 127 {
                    sb.str("\\u" + self.toInt().hex().lpad(4, "0"))
                } else {
                    sb.char(self)
                }
            }
        }
        sb.char('\'')
        sb.toString()
    }

    def unrepr(string: String): Self {
        Assert.that(string.startsWith("'") and string.endsWith("'"))
        val sb = StringBuilder()
        var escape = false
        val chars: List[Char] = []
        for ch in string[1:-1] {
            if escape {
                switch ch {
                    case '0' { chars.add('\0') }
                    case 'n' { chars.add('\n') }
                    case 'r' { chars.add('\r') }
                    case 't' { chars.add('\t') }
                    case '"' { chars.add('"') }
                    case '\\' { chars.add('\\') }
                    case '\'' { chars.add('\'') }
                    else = throw Error("Unrecognized escape char " + ch.repr())
                }
            } else if ch == '\\' {
                escape = true
            } else {
                chars.add(ch)
            }
        }
        Assert.equal(chars.size(), 1)
        chars[0]
    }

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
