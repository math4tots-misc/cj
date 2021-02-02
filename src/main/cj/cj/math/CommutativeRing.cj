package cj.math

trait CommutativeRing : Eq {
    def __get_zero(): Self
    def __get_one(): Self

    ## Computes the additive inverse
    def __neg(self): Self

    ## Commutative addition operation
    def __add(self, other: Self): Self

    ## Commutative multiplication operation
    def __mul(self, other: Self): Self

    def __sub(self, other: Self): Self = self + -other
}
