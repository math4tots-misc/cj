package cj.math

import cj.math.EuclideanDomain

trait Field : EuclideanDomain {

    ## Unlike with EuclideanDomains, we expect Fields to use '__div' for
    ## its division operator.
    def __div(self, other: Self): Self

    def edivrem(self, other: Self): Tuple[Self, Self] = (self / other, zero)
    def ediv(self, other: Self): Self = self / other
    def erem(self, other: Self): Self = zero
}
