package cj

native class Iterator[T?] : Iterable[T] {
    def iter(self: Self): Iterator[T]
    if T : NonNull def next(self: Self): Nullable[T]
    def toList(self: Self): List[T]

    def map[R](self: Self, f: Fn[T, R]): Iterator[R]
    def filter(self: Self, f: Fn[T, Bool]): Iterator[T]
    def reduce(self: Self, f: Fn[T, T, T]): T
    def fold[R](self: Self, start: R, f: Fn[R, T, R]): R
}
