package cj

import cj.Math
import cj.math.EuclideanDomain

@implicit(Char, _fromChar)
native class Int: Repr, Hash, Ord, ToBool, ToInt, ToDouble, ToChar, Default, EuclideanDomain {

    def __get_max(): Self = 2147483647
    def __get_min(): Self = -2147483648

    @implicit(Int, __new)
    @implicit(Double, fromDouble)
    @implicit(String, fromString)
    class Convertible {
        val x: Int
        def fromDouble(d: Int): Self = __malloc(d.toInt())
        def fromString(s: String): Self = __malloc(s.parseInt().get())
    }

    def(conv: Convertible): Self = conv.x
    def repr(self: Self): String = js!(String, "''+", self)
    def __eq(self: Self, other: Self): Bool = self is other
    def hash(self: Self): Int = self
    def __pos(a: Self): Int = a
    def __neg(a: Self): Int = js!(Int, "-", a)
    def abs(a: Self): Int = js!(Int, "Math.abs(", a, ")")
    def __invert(a: Self): Int = js!(Int, "~", a)
    def __add(a: Self, b: Self): Int = js!(Int, a, "+", b)
    def __sub(a: Self, b: Self): Int = js!(Int, a, "-", b)
    def __mul(a: Self, b: Self): Int = js!(Int, a, "*", b)
    def __rem(a: Self, b: Self): Int = js!(Int, a, "%", b)
    def __truncdiv(a: Self, b: Self): Int = js!(Int, "(", a, "/", b, ")|0")
    def __div(a: Self, b: Double): Double = js!(Double, a, "/", b)
    def __pow(a: Self, b: Double): Double = js!(Double, a, "**", b)
    def __lt(self: Self, other: Self): Bool = js!(Bool, self, "<", other)
    def __or(self: Self, other: Self): Self = js!(Self, self, "|", other)
    def __and(self: Self, other: Self): Self = js!(Self, self, "&", other)
    def __xor(self: Self, other: Self): Self = js!(Self, self, "^", other)
    def __lshift(self: Self, n: Self): Self = js!(Self, self, "<<", n)
    def __rshift(self: Self, n: Self): Self = js!(Self, self, ">>", n)
    def __rshiftu(self: Self, n: Self): Self = js!(Self, self, ">>>", n)
    def toBool(self: Self): Bool = js!(Bool, "!!", self)
    def toInt(self: Self): Int = self
    def toDouble(self: Self): Double = js!(Double, self)
    def toChar(self: Self): Char = js!(Char, self) # TODO: check for valid ranges
    def _fromChar(c: Char): Int = js!(Int, c)
    def default(): Int = 0
    def hex(self): String = js!(String, self, ".toString(16).toUpperCase()")
    def fromHex(hexString: String): Int = js!(Int, "parseInt(", hexString, ",16)")

    ## Round self up to the multiple of n
    def roundUp(self, n: Int): Int = (self + n - 1) // n * n

    # For EuclideanDomain
    def __get_zero(): Self = 0
    def __get_one(): Self = 1
    def edivrem(self, n: Self): Tuple[Self, Self] = (ediv(n), erem(n))
    def ediv(self, n: Self): Self = if n < 0 { -1 } else { 1 } * Math.floor(self / n.abs())
    def erem(self, n: Self): Self = self - n.abs() * Math.floor(self / n.abs())
}
