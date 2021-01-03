package cj

native class Iterator[T] : Iterable[T] {
    def iter(self: Self): Iterator[T]
}
