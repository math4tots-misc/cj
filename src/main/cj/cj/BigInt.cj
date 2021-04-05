package cj

import cj.math.Rational
import cj.math.EuclideanDomain

@implicit(Int, fromInt)
native class BigInt: Repr, Hash, Ord, ToBool, ToInt, ToDouble, Default, EuclideanDomain {

    @implicit(BigInt, __new)
    @implicit(Bool, fromBool)
    @implicit(Int, fromInt)
    @implicit(Double, fromDouble)
    @implicit(String, fromString)
    class Convertible {
        val x: BigInt
        def fromBool(b: Bool): Self = __malloc(if b { 1n } else { 0n })
        def fromInt(i: Int): Self = __malloc(i)
        def fromDouble(f: Double): Self = __malloc(BigInt.fromDouble(f))
        def fromString(s: String): Self = __malloc(BigInt.fromString(s))
    }

    def(conv: Convertible): Self = conv.x
    def fromString(s: String): Self = js!(Self, "BigInt(", s, ")")
    def fromInt(i: Int): Self = js!(Self, "BigInt(", i, ")")
    def fromDouble(d: Double): Self = js!(Self, "BigInt(", d, ")")
    def repr(self): String = js!(String, self, "+'n'")
    def toString(self): String = js!(String, "''+", self)
    def __eq(self, other: Self): Bool = js!(Bool, self, "===", other)
    def hash(self): Int = if abs() <= 0x7FFFFFFF {
        js!(Int, "Number(", self, ")|0") } else { toString().hash() }
    def __pos(self): Self = self
    def __neg(self): Self = js!(Self, "-", self)
    def abs(self): Self = js!(Self, self, "<0?-", self, ":", self)
    def __invert(self): Self = js!(Self, "~", self)
    def __add(self, other: Self): Self = js!(Self, self, "+", other)
    def __sub(self, other: Self): Self = js!(Self, self, "-", other)
    def __mul(self, other: Self): Self = js!(Self, self, "*", other)
    def __rem(self, other: Self): Self = js!(Self, self, "%", other)
    def __truncdiv(self, other: Self): Self = js!(Self, self, "/", other)
    def __div(self, other: Self): Rational = Rational(self, other)
    def ipow(self, n: Int): Self = js!(Self, self, "**BigInt(", n, ")")
    def __lt(self, other: Self): Bool = js!(Bool, self, "<", other)
    def __or(self, other: Self): Self = js!(Self, self, "|", other)
    def __and(self, other: Self): Self = js!(Self, self, "&", other)
    def __xor(self, other: Self): Self = js!(Self, self, "^", other)
    def ilshift(self, n: Int): Self = js!(Self, self, "<<BigInt(", n, ")")
    def irshift(self, n: Int): Self = js!(Self, self, ">>BigInt(", n, ")")
    def toBool(self): Bool = js!(Bool, "!!", self)
    def toInt(self): Int = js!(Int, "Number(", self, ")|0")
    def toDouble(self): Double = js!(Double, "Number(", self, ")")
    def default(): Self = 0n
    def isNegative(self): Bool = self < 0
    def hex(self): String = js!(String, self, ".toString(16).toUpperCase()")

    # for EuclideanDomain
    def __get_zero(): Self = 0n
    def __get_one(): Self = 1n
    def edivrem(self, other: Self): Tuple[Self, Self] = (ediv(self, other), erem(self, other))
    def ediv(a: Self, n: Self): Self = (if n < 0n { -1n } else { 1n }) * floordiv(a, n.abs())
    def erem(a: Self, n: Self): Self = a - n.abs() * floordiv(a, n.abs())

    def floordiv(a: Self, b: Self): Self {
        val d = js!(Self, a, "/", b)
        if (a < 0n and b > 0n or a > 0n and b < 0n) and a % b != 0n { d - 1n } else { d }
    }
}
