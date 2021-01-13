package cj

native class Iterator[T?] : Iterable[T] {
    def iter(self: Self): Iterator[T]
    if T : NonNull def next(self: Self): Nullable[T]
    def toList(self: Self): List[T]
}
