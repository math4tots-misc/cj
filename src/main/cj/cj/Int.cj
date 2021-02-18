package cj

import cj.math.EuclideanDomain

@implicit(Char, _fromChar)
native class Int: Repr, Hash, Ord, ToBool, ToInt, ToDouble, ToChar, Default, EuclideanDomain {

    @implicit(Int, __new)
    @implicit(Double, fromDouble)
    @implicit(String, fromString)
    class Converter {
        val x: Int
        def fromDouble(d: Int): Self = __malloc(d.toInt())
        def fromString(s: String): Self = __malloc(s.parseInt().get())
    }

    def(x: Converter): Self
    def repr(self: Self): String
    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
    def __pos(a: Self): Int
    def __neg(a: Self): Int
    def abs(a: Self): Int
    def __invert(a: Self): Int
    def __add(a: Self, b: Self): Int
    def __sub(a: Self, b: Self): Int
    def __mul(a: Self, b: Self): Int
    def __rem(a: Self, b: Self): Int
    def __truncdiv(a: Self, b: Self): Int
    def __div(a: Self, b: Double): Double
    def __pow(a: Self, b: Double): Double
    def __lt(self: Self, other: Self): Bool
    def __or(self: Self, other: Self): Self
    def __and(self: Self, other: Self): Self
    def __lshift(self: Self, n: Self): Self
    def __rshift(self: Self, n: Self): Self
    def __rshiftu(self: Self, n: Self): Self
    def toBool(self: Self): Bool
    def toInt(self: Self): Int
    def toDouble(self: Self): Double
    def toChar(self: Self): Char
    def _fromChar(c: Char): Int
    def default(): Int
    def hex(self): String

    # For EuclideanDomain
    def __get_zero(): Self
    def __get_one(): Self
    def edivrem(self, other: Self): Tuple[Self, Self]
    def ediv(self, other: Self): Self
    def erem(self, other: Self): Self
}
