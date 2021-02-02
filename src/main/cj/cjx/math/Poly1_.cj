package cjx.math

import cjx.math.Poly1
import cj.math.CommutativeRing

class Poly1_ {

    @variadic def new[R: CommutativeRing](coefs: List[R]): Poly1[R] = (
        Poly1[R].fromCoefficients(coefs))

    def fromCoefficients[R: CommutativeRing](coefs: List[R]): Poly1[R] = (
        Poly1[R].fromCoefficients(coefs))
}
