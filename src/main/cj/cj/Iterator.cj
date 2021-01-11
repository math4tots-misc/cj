package cj

native class Iterator[T] : Iterable[T] {
    def iter(self: Self): Iterator[T]
    def next(self: Self): Nullable[T]
    def toList(self: Self): List[T]
}
