package cj

trait Iterable[T] {
    def iter(self: Self): Iterator[T]
}