package cj

native class BigInt: Repr, Hash, Ord, ToBool, ToInt, ToDouble, Default {
    def fromString(s: String): Self
    def fromInt(i: Int): Self
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
}
