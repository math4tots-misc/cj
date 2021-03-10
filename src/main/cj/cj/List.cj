package cj

import cj.StringBuilder
import cj.Approximate
import cj.Collection

native class List[T?] :
        Collection[T],
        ToBool,
        Default,
        Eq if T : Eq,
        Hash if T : Hash,
        Approximate if T : Approximate,
        Repr if T : Repr {
    @generic def empty(): Self
    @variadic @generic def(list: Self): Self
    @generic def iter(self: Self): Iterator[T]
    @generic def iterFrom(self: Self, start: Int): Iterator[T]
    @generic def size(self: Self): Int
    @generic def isEmpty(self: Self): Bool
    @generic def add(self: Self, t: T)
    @genericSelf def addAll[C: Iterable[T]](self: Self, ts: C) { for t in ts { add(t) } }
    @generic def pop(self): T
    @generic def __add(self: Self, other: Self): Self
    @generic def __getitem(self: Self, i: Int): T
    @generic def __setitem(self: Self, i: Int, t: T)
    @generic def removeIndex(self: Self, i: Int): T
    @generic def insert(self: Self, i: Int, t: T)
    @generic def last(self: Self): T
    @generic def swap(self, i: Int, j: Int)
    @generic def __slice(self, start: Int, end: Int): Self
    @generic def __sliceFrom(self, start: Int): Self
    @generic def __sliceTo(self, end: Int): Self

    @generic def __mul(self: Self, n: Int): Self

    @generic def map[R?](self: Self, f: Fn[T, R]): List[R]
    @generic def filter(self: Self, f: Fn[T, Bool]): Self
    @generic def clone(self): Self

    @generic def _clearListWithSize(size: Int): Self
    @generic def _clearItem(self, i: Int)

    def toBool(self: Self): Bool

    def toList(self: Self): Self

    def default(): Self

    def flatMap[@generic R, C: Iterable[R]](self, f: Fn[T, C]): List[R]
    def flatten[@generic R, C: Iterable[R]](self: List[C]): List[R]

    if T : Eq def __contains(self, t: T): Bool
    if T : Ord def sort(self) = _sortByCmp((a, b) -> a.__cmp(b))
    def sortBy[X: Ord](self, f: Fn[T, X]) = _sortByCmp((a, b) -> f.call(a).__cmp(f.call(b)))
    def _sortByCmp(self, f: Fn[T, T, Int])
    @generic def reverse(self)
    if T : Eq def __eq(self: Self,  other: Self): Bool {
        if size() != other.size() {
            return false
        }
        for i = 0; i < size(); i++ {
            if self[i] != other[i] {
                return false
            }
        }
        true
    }
    if T : Hash def hash(self: Self): Int
    if T : Approximate def approximates(self: Self, other: Self, tolerance: Double): Int
    if T : Repr def repr(self: Self): String = "[" + ", ".join(map(t -> t.repr())) + "]"
}
