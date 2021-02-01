package cj

trait EuclideanDomain : Eq {
    def __get_zero(): Self
    def __get_one(): Self

    ## Computes the additive inverse
    def __neg(self): Self

    ## Commutative addition operation
    def __add(self, other: Self): Self

    ## Commutative multiplication operation
    def __mul(self, other: Self): Self

    def __sub(self, other: Self): Self = self + -other

    ## Euclidean division with remainder.
    ## This may or may not be the same as __div and __rem
    def edivrem(self, other: Self): Tuple[Self, Self]

    ## Euclidean Division.
    ## This may or may not be the same as __div
    def ediv(self, other: Self): Self = edivrem(other).get0()

    ## Euclidean Remainder.
    ## This may or may not be the same as __rem
    def erem(self, other: Self): Self = edivrem(other).get1()

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
