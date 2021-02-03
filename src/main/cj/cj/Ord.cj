package cj

trait Ord {
    def __lt(self: Self, other: Self): Bool
    def __gt(self: Self, other: Self): Bool = other < self
    def __le(self: Self, other: Self): Bool = not (other < self)
    def __ge(self: Self, other: Self): Bool = not (self < other)
    def __cmp(self, other: Self): Int = (
        if self < other { -1 } else if other < self { 1 } else { 0 })
}
