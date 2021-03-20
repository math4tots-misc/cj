package cj

native class Iterator[T?] : Iterable[T] {
    @generic def iter(self: Self): Iterator[T]
    @generic if T : NonNull def next(self: Self): Nullable[T]
    @generic def nextOrElse(self: Self, f: Fn[T]): T
    @generic def toList(self: Self): List[T]

    @generic def forEach(self, f: Fn[T, Unit]) {
        for t in self {
            f.call(t)
        }
    }
    @generic def map[R?](self: Self, f: Fn[T, R]): Iterator[R]
    @generic def filter(self: Self, f: Fn[T, Bool]): Iterator[T]
    @generic def reduce(self: Self, f: Fn[T, T, T]): T
    @generic def fold[R?](self: Self, start: R, f: Fn[R, T, R]): R
    @genericSelf def flatMap[@generic X?, R?: Iterable[X]](self: Self, f: Fn[T, R]): Iterator[X] = (
        _flatMap(t -> f.call(t).iter()))
    @generic def _flatMap[X?](self, f: Fn[T, Iterator[X]]): Iterator[X]
}
