package cj

import cj.math.Rational
import cj.math.EuclideanDomain

@implicit(Int, fromInt)
@implicit(Double, fromDouble)
native class BigInt: Repr, Hash, Ord, ToBool, ToInt, ToDouble, Default, EuclideanDomain {

    @implicit(Int, fromInt)
    @implicit(Double, fromDouble)
    @implicit(String, fromString)
    class Converter {
        val x: BigInt
        def fromInt(i: Int): Self = __malloc(i)
        def fromDouble(f: Int): Self = __malloc(f)
        def fromString(s: String): Self = __malloc(BigInt.fromString(s))
    }

    def __new(x: Converter): Self
    def fromString(s: String): Self
    def fromInt(i: Int): Self
    def fromDouble(d: Double): Self
    def repr(self): String
    def toString(self): String
    def __eq(self, other: Self): Bool
    def hash(self): Int
    def __pos(self): Self
    def __neg(self): Self
    def abs(self): Self
    def __invert(self): Self
    def __add(self, other: Self): Self
    def __sub(self, other: Self): Self
    def __mul(self, other: Self): Self
    def __rem(self, other: Self): Self
    def __truncdiv(self, other: Self): Self
    def __div(self, other: Self): Rational
    def ipow(self, n: Int): Self
    def __lt(self, other: Self): Bool
    def __or(self, other: Self): Self
    def __and(self, other: Self): Self
    def ilshift(self, n: Int): Self
    def irshift(self, n: Int): Self
    def toBool(self): Bool
    def toInt(self): Int
    def toDouble(self): Double
    def default(): Self
    def isNegative(self): Bool
    def hex(self): String

    # for EuclideanDomain
    def __get_zero(): Self
    def __get_one(): Self
    def edivrem(self, other: Self): Tuple[Self, Self]
    def ediv(self, other: Self): Self
    def erem(self, other: Self): Self
}
