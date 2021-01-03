package cj

class List[T] : Iterable[T] {
    def size(self: Self): Int
    def isEmpty(self: Self): Bool
    def add(self: Self, t: T)
}
