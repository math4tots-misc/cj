package cj

import cj.math.Field
import cj.Approximate

@implicit(Int, _fromInt)
native class Double: Repr, Hash, Approximate, Ord, ToBool, ToInt, ToDouble, Default, Field {

    @implicit(Double, __new)
    @implicit(Int, fromInt)
    @implicit(String, fromString)
    class Convertible {
        val x: Double
        def fromInt(i: Int): Self = __malloc(i.toDouble())
        def fromString(s: String): Self = __malloc(s.parseDouble().get())
    }

    def(x: Convertible): Self
    def repr(self: Self): String
    def __eq(self: Self, other: Self): Bool
    def approximates(self: Self, other: Self, tolerance: Double): Bool
    def hash(self: Self): Int
    def toBool(self: Self): Bool
    def toInt(self: Self): Int
    def toDouble(self: Self): Double
    def _fromInt(i: Int): Double

    def __lt(self: Self, other: Self): Bool
    def __add(self: Self, other: Self): Double
    def __sub(self: Self, other: Self): Double
    def __mul(self: Self, other: Self): Double
    def __div(self: Self, other: Self): Double
    def __rem(self: Self, other: Self): Double
    def __truncdiv(self: Self, other: Self): Int
    def __pow(self: Self, other: Self): Self
    def __neg(self: Self): Double
    def abs(self: Self): Double

    ## formats a number using fixed-point notation, up to the specified number
    ## digits after the decimal point.
    ## (compare with Javascript's Number.prototype.toFixed)
    def toFixed(self: Self, n: Int): String

    def default(): Self

    # for Field trait
    def __get_zero(): Self
    def __get_one(): Self
}
