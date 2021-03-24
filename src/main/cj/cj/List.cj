package cj

import cj.Error
import cj.Math
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

    @generic private def checkedIndex(self, var i: Int): Int {
        if i < 0 {
            i += size()
        }
        if i < 0 or i >= size() {
            IO.panic("Index out of bounds (i = " + i + ", len = " + size() + ")")
        }
        i
    }
    @generic private def checkedIndex2(self, var i: Int): Int {
        if i < 0 {
            i += size()
        }
        if i < 0 or i > size() {
            IO.panic("Index out of bounds (i = " + i + ", len = " + size() + ")")
        }
        i
    }

    @generic def empty(): Self = []
    @variadic @generic def of(self): Self = self
    @generic def iter(self: Self): Iterator[T] = js!(Iterator[T], self, "[Symbol.iterator]()")
    @generic def iterFrom(self: Self, start: Int): Iterator[T]
    @generic def size(self: Self): Int = js!(Int, self, ".length")
    @generic def isEmpty(self: Self): Bool = js!(Bool, self, ".length==0")
    @generic def add(self: Self, t: T) = js!(Unit, self, ".push(", t, ")")
    @genericSelf def addAll[C: Iterable[T]](self: Self, ts: C) { for t in ts { add(t) } }
    @generic def pop(self): T {
        if self { js!(T, self, ".pop()") } else { throw Error("Pop from empty list") }
    }
    @generic def __add(self: Self, other: Self): Self {
        val ret = clone()
        ret.addAll(other)
        ret
    }
    @generic def __getitem(self: Self, i: Int): T = js!(T, self, "[", checkedIndex(i), "]")
    @generic def __setitem(self: Self, i: Int, t: T) = js!(T, self, "[", checkedIndex(i), "]=", t)
    @generic def removeIndex(self: Self, i: Int): T = js!(
        T, self, ".splice(", checkedIndex(i), ",1)[0]")
    @generic def insert(self: Self, i: Int, t: T) = js!(
        Unit, self, ".splice(", checkedIndex2(i), ",0,", t, ")")
    @generic def last(self: Self): T {
        if not self { IO.panic("last() called on empty list") }
        js!(T, self, "[", self, ".length-1]")
    }
    @generic def swap(self, i: Int, j: Int) {
        val tmp = self[i]
        self[i] = self[j]
        self[j] = tmp
    }
    @generic def __slice(self, start: Int, end: Int): Self = (
        js!(Self, self, ".slice(", checkedIndex2(start), ",", checkedIndex2(end), ")"))
    @generic def __sliceFrom(self, start: Int): Self = (
        js!(Self, self, ".slice(", checkedIndex2(start), ")"))
    @generic def __sliceTo(self, end: Int): Self = (
        js!(Self, self, ".slice(0,", checkedIndex2(end), ")"))

    @generic def __mul(self: Self, n: Int): Self {
        val ret: Self = []
        for i = 0; i < n; i++ {
            ret.addAll(self)
        }
        ret
    }

    @generic def map[R?](self: Self, f: Fn[T, R]): List[R] = js!(List[R], self, ".map(", f, ")")
    @generic def filter(self: Self, f: Fn[T, Bool]): Self = js!(Self, self, ".filter(", f, ")")
    @generic def clone(self): Self = js!(Self, "Array.from(", self, ")")

    @generic def _clearListWithSize(size: Int): Self = js!(Self, "Array(", size, ")")
    @generic def _clearItem(self, i: Int) = js!(Unit, self, "[", i, "]=undefined")

    def toBool(self: Self): Bool = js!(Bool, self, ".length!==0")

    def toList(self: Self): Self = js!(Self, "Array.from(", self, ")")

    def default(): Self = []

    def flatMap[@generic R, C: Iterable[R]](self, f: Fn[T, C]): List[R] {
        val ret: List[R] = []
        for t in self {
            for r in f.call(t) {
                ret.add(r)
            }
        }
        ret
    }

    def flatten[@generic R, C: Iterable[R]](self: List[C]): List[R] {
        val ret: List[R] = []
        for c in self {
            for r in c {
                ret.add(r)
            }
        }
        ret
    }

    if T : Eq def __contains(self, t: T): Bool = iter().any(x -> x == t)
    if T : Ord def sort(self) = _sortByCmp((a, b) -> a.__cmp(b))
    def sortBy[X: Ord](self, f: Fn[T, X]) = _sortByCmp((a, b) -> f.call(a).__cmp(f.call(b)))
    def _sortByCmp(self, f: Fn[T, T, Int]) = js!(Unit, self, ".sort(", f, ")")
    @generic def reverse(self) = js!(Unit, self, ".reverse()")
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
    if T : Hash def hash(self: Self): Int {
        var h = 1
        for item in self {
            h = Math.combineHash(h, item.hash())
        }
        h
    }
    if T : Approximate def approximates(self: Self, other: Self, tolerance: Double): Bool {
        if size() != other.size() {
            return false
        }
        for i = 0; i < size(); i++ {
            if not self[i].approximates(other[i], tolerance) {
                return false
            }
        }
        true
    }
    if T : Repr def repr(self: Self): String = "[" + ", ".join(map(t -> t.repr())) + "]"
}
