package cj

## For things that can be approximately compared
trait Approximate {
    def approximates(self, other: Self, tolerance: Double): Bool
}
