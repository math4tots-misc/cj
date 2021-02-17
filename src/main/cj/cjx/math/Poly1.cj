package cjx.math

import cj.StringBuilder
import cj.Math
import cj.math.Field
import cj.math.EuclideanDomain
import cj.math.CommutativeRing

## Polynomial over a single variable
class Poly1[R : CommutativeRing] :
        Eq,
        Hash if R : Hash,
        Repr if R : Repr,
        EuclideanDomain if R : Field {

    val coefs : List[R]

    @variadic def(coefs: List[R]): Self = fromCoefficients(coefs)

    def fromCoefficients(coefs: List[R]): Self = {
        while coefs and coefs.last() == R.zero {
            coefs.pop()
        }
        __malloc(coefs)
    }

    def __get_zero(): Self = Self()
    def __get_one(): Self = Self(R.one)
    def __get_x(): Self = Self(R.zero, R.one)

    def apply(self, x: R): R = {
        var result = R.zero
        var factor = R.one
        for c in coefs {
            result = result + c * factor
            factor = factor * x
        }
        result
    }

    def degree(self) : Int = if coefs { coefs.size() - 1 } else { 0 }

    def __eq(self, other: Self): Bool = coefs == other.coefs

    if R : Hash def hash(self): Int = coefs.hash()

    if R : Repr def repr(self): String = {
        val sb = StringBuilder()
        sb.add("Poly1(")
        for i = 0; i < coefs.size(); i++ {
            if i {
                sb.add(", ")
            }
            sb.add(coefs[i].repr())
        }
        sb.add(")")
        sb.toString()
    }

    if R : ToString def toString(self): String = {
        val zero = R.zero
        val one = R.one
        val sb = StringBuilder()
        if coefs {
            var started = false
            val coef0 = coefs[0]
            if coef0 != zero {
                started = true
                sb.add(coefs[0].toString())
            }
            for i = 1; i < coefs.size(); i++ {
                if started {
                    sb.add(" + ")
                }
                val coef = coefs[i]
                if coef != zero {
                    started = true
                    if coef != one {
                        sb.add(coef.toString())
                    }
                    sb.add("x")
                    if i > 1 {
                        sb.add(i.toString())
                    }
                }
            }
        } else {
            sb.add(R.zero.toString())
        }
        sb.toString()
    }

    def __neg(self): Self = fromCoefficients(coefs.map(c -> -c))

    def __add(self, other: Self): Self = {
        val cs : List[R] = []
        val xs = self.coefs
        val ys = other.coefs
        val min = Math.min(xs.size(), ys.size())
        for i = 0; i < min; i++ {
            cs.add(xs[i] + ys[i])
        }
        for j = min; j < xs.size(); j++ {
            cs.add(xs[j])
        }
        for j = min; j < ys.size(); j++ {
            cs.add(ys[j])
        }
        Self.fromCoefficients(cs)
    }

    def __mul(self, other: Self): Self = {
        val xs = self.coefs
        val ys = other.coefs
        val xlen = xs.size()
        val ylen = ys.size()
        val cs = [R.zero] * (xlen + ylen)
        for i = 0; i < xlen; i++ {
            val x = xs[i]
            for j = 0; j < ylen; j++ {
                val y = ys[j]
                cs[i + j] = cs[i + j] + x * y
            }
        }
        Self.fromCoefficients(cs)
    }

    # if R : Field def edivrem(self, other: Self): Tuple[Self, Self] = {
    # }
}
