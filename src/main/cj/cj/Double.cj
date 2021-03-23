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

    def(conv: Convertible): Self = conv.x
    def repr(self: Self): String = js!(String, "''+", self)
    def __eq(self: Self, other: Self): Bool = self is other
    def approximates(self: Self, other: Self, tolerance: Double): Bool = js!(
        Bool, "appx(", self, ",", other, ",", tolerance, ")")
    def hash(self: Self): Int = js!(Int, "(10000*(", self, "))|0")
    def toBool(self: Self): Bool = js!(Bool, "!!", self)
    def toInt(self: Self): Int = js!(Int, self, "|0")
    def toDouble(self: Self): Double = self
    def _fromInt(i: Int): Double = js!(Double, i)

    def __lt(self: Self, other: Self): Bool = js!(Bool, self, "<", other)
    def __add(self: Self, other: Self): Double = js!(Double, self, "+", other)
    def __sub(self: Self, other: Self): Double = js!(Double, self, "-", other)
    def __mul(self: Self, other: Self): Double = js!(Double, self, "*", other)
    def __div(self: Self, other: Self): Double = js!(Double, self, "/", other)
    def __rem(self: Self, other: Self): Double = js!(Double, self, "%", other)
    def __truncdiv(self: Self, other: Self): Int = js!(Int, "(", self, "/", other, ")|0")
    def __pow(self: Self, other: Self): Self = js!(Self, self, "**", other)
    def __neg(self: Self): Double = js!(Self, "-", self)
    def abs(self: Self): Double = js!(Self, "Math.abs(", self, ")")

    ## formats a number using fixed-point notation, up to the specified number
    ## digits after the decimal point.
    ## (compare with Javascript's Number.prototype.toFixed)
    def toFixed(self: Self, n: Int): String = js!(String, self, ".toFixed(", n, ")")

    def default(): Self = 0

    # for Field trait
    def __get_zero(): Self = 0
    def __get_one(): Self = 1
}
