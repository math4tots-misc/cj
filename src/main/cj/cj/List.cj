package cj

import cj.Collection

native class List[T?] :
        Collection[T],
        ToBool,
        Default,
        Hash if T : Hash,
        Repr if T : Repr {
    @generic def empty(): Self

    @generic def iter(self: Self): Iterator[T]
    @generic def size(self: Self): Int
    @generic def isEmpty(self: Self): Bool
    @generic def add(self: Self, t: T)
    @generic def __getitem(self: Self, i: Int): T
    @generic def __setitem(self: Self, i: Int, t: T)
    @generic def removeIndex(self: Self, i: Int): T
    @generic def insert(self: Self, i: Int, t: T)
    @generic def last(self: Self): T

    @generic def __mul(self: Self, n: Int): Self

    @generic def map[R?](self: Self, f: Fn[T, R]): List[R]
    @generic def filter(self: Self, f: Fn[T, Bool]): Self

    def toBool(self: Self): Bool

    def toList(self: Self): Self

    def default(): Self

    if T : Hash def __eq(self: Self,  other: Self): Bool
    if T : Hash def hash(self: Self): Int
    if T : Repr def repr(self: Self): String
}
