package cj.math

import cj.math.CommutativeRing

trait EuclideanDomain : CommutativeRing {
    ## Euclidean division with remainder.
    ## This may or may not be the same as __div and __rem
    def edivrem(self, other: Self): Tuple[Self, Self]

    ## Euclidean Division.
    ## This may or may not be the same as __div
    def ediv(self, other: Self): Self = edivrem(other).f0

    ## Euclidean Remainder.
    ## This may or may not be the same as __rem
    def erem(self, other: Self): Self = edivrem(other).f1

    ## Compute the GCD with the euclidean algorithm
    def gcd(var a: Self, var b: Self): Self = {
        val zero = Self.zero
        while b != zero {
            val t = b
            b = a.erem(b)
            a = t
        }
        a
    }
}
