package cj

@implicit(Int, _fromInt)
native class Double: Repr, Hash, Ord, ToBool, ToInt, ToDouble {
    def repr(self: Self): String
    def __eq(self: Self, other: Self): Bool
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
    def __mod(self: Self, other: Self): Double
    def __truncdiv(self: Self, other: Self): Int
}
