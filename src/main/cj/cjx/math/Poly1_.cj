package cjx.math

import cjx.math.Poly1
import cj.math.CommutativeRing

class Poly1_ {

    def[R: CommutativeRing](coefs: List[R]): Poly1[R] = (
        Poly1[R].fromCoefficients(coefs))

    def fromCoefficients[R: CommutativeRing](coefs: List[R]): Poly1[R] = (
        Poly1[R].fromCoefficients(coefs))
}
