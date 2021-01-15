package cj

native class Int: Repr, Hash, Ord, ToBool, ToInt, ToDouble, ToChar {
    def repr(self: Self): String
    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
    def __pos(a: Self): Int
    def __neg(a: Self): Int
    def __invert(a: Self): Int
    def __add(a: Self, b: Self): Int
    def __sub(a: Self, b: Self): Int
    def __mul(a: Self, b: Self): Int
    def __mod(a: Self, b: Self): Int
    def __rem(a: Self, b: Self): Int
    def __truncdiv(a: Self, b: Self): Int
    def __div(a: Self, b: Self): Double
    def __lt(self: Self, other: Self): Bool
    def toBool(self: Self): Bool
    def toInt(self: Self): Int
    def toDouble(self: Self): Double
    def toChar(self: Self): Char
}
