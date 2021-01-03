package cj

native class List[T] : Iterable[T] {
    def iter(self: Self): Iterator[T]
    def size(self: Self): Int
    def isEmpty(self: Self): Bool
    def add(self: Self, t: T)
}
