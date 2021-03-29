package cj

import cj.Error
import cj.StringBuilder
import cj.BufferLike
import cj.Uint8Array
import cj.Math

native class String: Repr, ToBool, Hash, Ord, Iterable[Char], Default {
    def checkedIndex(self, var i: Int): Int {
        if i < 0 {
            i += len()
        }
        if i < 0 or i >= len() {
            IO.panic("String index out of bounds (i = " + i + ", len = " + len() + ")")
        }
        i
    }

    def toString(self: Self): Self = self

    def repr(self: Self): String {
        val sb = StringBuilder()
        sb.char('"')
        for ch in self {
            switch ch {
                case '\0' = sb.str("\\0")
                case '\n' = sb.str("\\n")
                case '\r' = sb.str("\\r")
                case '\t' = sb.str("\\t")
                case '"' = sb.str("\\\"")
                else {
                    if ch.toInt() < 32 {
                        sb.str("\\x" + ch.toInt().hex().lpad(2, "0"))
                    } else if ch.toInt() >= 127 {
                        sb.str("\\u" + ch.toInt().hex().lpad(4, "0"))
                    } else {
                        sb.char(ch)
                    }
                }
            }
        }
        sb.char('"')
        sb.toString()
    }

    def unrepr(self): String {
        Assert.that(startsWith("\"") and endsWith("\""))
        val sb = StringBuilder()
        var escape = false
        for ch in self[1:-1] {
            if escape {
                switch ch {
                    case '0' { sb.char('\0') }
                    case 'n' { sb.char('\n') }
                    case 'r' { sb.char('\r') }
                    case 't' { sb.char('\t') }
                    case '"' { sb.char('"') }
                    case '\\' { sb.char('\\') }
                    else = throw Error("Unrecognized escape char " + ch.repr())
                }
            } else if ch == '\\' {
                escape = true
            } else {
                sb.char(ch)
            }
        }
        sb.toString()
    }

    def __add[T?: ToString](self: Self, other: T): Self = js!(Self, self, "+", other.toString())

    ## Number of char codes in this string.
    ## NOTE: If the default encoding is UTF-16, this is neither the number of bytes
    ## nor the number of code points.
    def size(self: Self): Int = js!(Int, self, ".length")  # deprecated, use len()
    def len(self: Self): Int = js!(Int, self, ".length")

    def toBool(self: Self): Bool = js!(Bool, "!!", self)

    def __eq(self: Self, other: Self): Bool = self is other

    def hash(self: Self): Int {
        var h = 0;
        for c in self {
            h = Math.combineHash(h, c.hash())
        }
        h
    }
    def __lt(self, other: Self): Bool = js!(Bool, self, "<", other)

    def __contains(self, other: Self): Bool = js!(Bool, self, ".includes(", other, ")")

    def join[T?: ToString, C?: Iterable[T]](self: Self, parts: C): String = _join(
        parts.iter().map(p -> p.toString()).toList())

    def _join(self, parts: List[String]): String = js!(String, parts, ".join(", self, ")")

    def charCodeAt(self: Self, i: Int): Int =  js!(
        Char, "defined(", self, ".charCodeAt(", i, "))")
    def charAt(self: Self, i: Int): Char = js!(Char, "defined(", self, ".codePointAt(", i, "))")
    def iter(self: Self): Iterator[Char] = js!(Iterator[Char], "strIter(", self, ")")

    def __getitem(self, i: Int): Char = charAt(checkedIndex(i))

    def __slice(self, start: Int, end: Int): Self = js!(
        Self, self, ".slice(", start, ",", end, ")")
    def __sliceFrom(self, start: Int): Self = js!(Self, self, ".slice(", start, ")")
    def __sliceTo(self, end: Int): Self = js!(Self, self, ".slice(0,", end, ")")

    def __mul(self, n: Int): String = js!(String, self, ".repeat(", n, ")")

    ## Return a new string repeatedly padded with the given prefix until the
    ## final length is at least as long as length
    def lpad(self, length: Int, prefix: String): String {
        var ret = self
        while ret.len() < length {
            ret = prefix + ret
        }
        ret
    }

    ## Return a new string repeatedly padded with the given suffix until the
    ## final length is at least as long as length
    def rpad(self, length: Int, suffix: String): String {
        var ret = self
        while ret.len() < length {
            ret = ret + suffix
        }
        ret
    }

    def lstripChar(self, ch: Char): String {
        val s = ch.toString()
        var start = 0
        while startsWithAt(s, start) {
            start += s.len()
        }
        self[start:]
    }
    def rstripChar(self, ch: Char): String {
        val s = ch.toString()
        var end = len()
        while endsWithAt(s, end) {
            end -= s.len()
        }
        self[:end]
    }

    def parseInt(self: Self): Nullable[Int]
    def parseDouble(self: Self): Nullable[Double]

    def startsWith(self, prefix: String): Bool = js!(
        Bool, self, ".startsWith(", prefix, ")")
    def startsWithAt(self, prefix: String, startIndex: Int): Bool = js!(
        Bool, self, ".startsWith(", prefix, ",", startIndex, ")")
    def endsWith(self, suffix: String): Bool = js!(
        Bool, self, ".endsWith(", suffix, ")")
    def endsWithAt(self, suffix: String, endIndex: Int): Bool = js!(
        Bool, self, ".endsWith(", suffix, ",", endIndex, ")")

    def trim(self: Self): String = js!(String, self, ".trim()")
    def lower(self): String = js!(String, self, ".toLowerCase()")
    def upper(self): String = js!(String, self, ".toUpperCase()")
    def replace(self, old: String, new: String): String = js!(
        String, self, ".split(", old, ").join(", new, ")")

    def split(self, sep: String): List[String] {
        if sep {
            js!(List[String], self, ".split(", sep, ")")
        } else {
            # this way surrogate pairs are preserved
            js!(List[String], "Array.from(", self, ")")
        }
    }

    ## Return -1 if not found
    def indexOf(self, substring: String): Int = js!(Int, self, ".indexOf(", substring, ")")

    ## Return -1 if not found
    def lastIndexOf(self, substring: String): Int = js!(Int, self, ".lastIndexOf(", substring, ")")

    def sizeUTF8(self): Int = toUTF8().size()
    def toUTF8(self): Uint8Array = js!(Uint8Array, "new TextEncoder().encode(", self, ")")
    def fromUTF8[B: BufferLike](b: B): String = js!(
        String, "new TextDecoder().decode(", b.asUint8Array(), ")")

    def default(): Self = ""
}
