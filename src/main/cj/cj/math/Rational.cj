package cj.math

import cj.Error
import cj.math.Field
import cj.BigInt

@implicit(Int, fromInt)
@implicit(BigInt, fromBigInt)
class Rational : Hash, Ord, Repr, ToBool, Field {
    val numerator : BigInt
    val denominator : BigInt

    def(numerator: BigInt, denominator: BigInt): Self = {
        if denominator == 0n {
            throw Error("Division by zero")
        }
        val gcd = numerator.gcd(denominator)
        var n = numerator.ediv(gcd)
        var d = denominator.ediv(gcd)
        if d.isNegative() {
            n = -n
            d = -d
        }
        __malloc(n, d)
    }

    def fromBigInt(bi: BigInt): Self = __malloc(bi, 1n)
    def fromInt(i: Int): Self = __malloc(i, 1n)

    def __pos(self): Self = self
    def __neg(self): Self = __malloc(-numerator, denominator)
    def abs(self): Self = __malloc(numerator.abs(), denominator)
    def __add(self, other: Self): Self = Self(
        numerator * other.denominator + other.numerator * denominator,
        denominator * other.denominator)
    def __sub(self, other: Self): Self = Self(
        numerator * other.denominator - other.numerator * denominator,
        denominator * other.denominator)
    def __mul(self, other: Self): Self = Self(
        numerator * other.numerator, denominator * other.denominator)
    def __div(self, other: Self): Self = Self(
        numerator * other.denominator, denominator * other.numerator)
    def __truncdiv(self, other: Self): BigInt = (
        (numerator * other.denominator) // (denominator * other.numerator))

    def __eq(self, other: Self): Bool = (
        numerator == other.numerator and denominator == other.denominator)
    def hash(self): Int = (numerator, denominator).hash()
    def __lt(self, other: Self): Bool = (
        numerator * other.denominator < other.numerator * denominator)
    def toString(self): String = "" + numerator + "/" + denominator
    def repr(self): String = "Rational(" + numerator + ", " + denominator + ")"
    def toBool(self): Bool = numerator.toBool()

    # for Field trait
    def __get_zero(): Self = 0
    def __get_one(): Self = 1
}
