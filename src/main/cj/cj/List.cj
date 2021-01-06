package cj

native class List[T] :
        Iterable[T],
        Repr if T : Repr {
    def empty(): Self

    def iter(self: Self): Iterator[T]
    def size(self: Self): Int
    def isEmpty(self: Self): Bool
    def add(self: Self, t: T)

    def map[R](self: Self, f: Fn[T, R]): List[R]

    if T : Repr
    def repr(self: Self): String
}
