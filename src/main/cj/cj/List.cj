package cj

native class List[T] :
        Iterable[T],
        ToBool,
        Hash if T : Hash,
        Repr if T : Repr {
    def empty(): Self

    def iter(self: Self): Iterator[T]
    def size(self: Self): Int
    def isEmpty(self: Self): Bool
    def add(self: Self, t: T)
    def get(self: Self, i: Int): T
    def set(self: Self, i: Int, t: T)

    def map[R](self: Self, f: Fn[T, R]): List[R]
    def filter(self: Self, f: Fn[T, Bool]): Self

    def toBool(self: Self): Bool

    def toList(self: Self): Self

    if T : Hash def __eq(self: Self,  other: Self): Bool
    if T : Hash def hash(self: Self): Int
    if T : Repr def repr(self: Self): String
}
