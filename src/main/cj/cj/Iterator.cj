package cj

native class Iterator[T?] : Iterable[T] {
    @generic def iter(self: Self): Iterator[T]
    @generic if T : NonNull def next(self: Self): Nullable[T]
    @generic def toList(self: Self): List[T]

    @generic def map[R](self: Self, f: Fn[T, R]): Iterator[R]
    @generic def filter(self: Self, f: Fn[T, Bool]): Iterator[T]
    @generic def reduce(self: Self, f: Fn[T, T, T]): T
    @generic def fold[R](self: Self, start: R, f: Fn[R, T, R]): R
}
