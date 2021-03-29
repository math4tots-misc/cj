package cj

import cj.Approximate
import cj.Math
import cj.Collection

trait NativeArrayLike[T]: Collection[T] {

    def checkedIndex(self, var i: Int): Int {
        if i < 0 {
            i += size()
        }
        if i < 0 or i >= size() {
            IO.panic("Index out of bounds (i = " + i + ", len = " + size() + ")")
        }
        i
    }

    def checkedIndex2(self, var i: Int): Int {
        if i < 0 {
            i += size()
        }
        if i < 0 or i > size() {
            IO.panic("Index out of bounds (i = " + i + ", len = " + size() + ")")
        }
        i
    }

    def iter(self): Iterator[T] = js!(Iterator[T], self, "[Symbol.iterator]()")

    def __getitem(self: Self, i: Int): T = js!(T, self, "[", checkedIndex(i), "]")
    def __setitem(self: Self, i: Int, t: T) = js!(T, self, "[", checkedIndex(i), "]=", t)

    def __slice(self, start: Int, end: Int): Self = js!(
        Self, self, ".slice(", start, ",", end, ")")
    def __sliceFrom(self, start: Int): Self = js!(Self, self, ".slice(", start, ")")
    def __sliceTo(self, end: Int): Self = js!(Self, self, ".slice(0,", end, ")")

    def size(self): Int = js!(Int, self, ".length")

    def toList(self): List[T] = js!(List[T], "Array.from(", self, ")")

    if T : Hash def hash(self): Int {
        var h = 1
        for t in self {
            h = Math.combineHash(h, t.hash())
        }
        h
    }

    if T : Eq def __eq(self, other: Self): Bool {
        val len = size()
        if len != other.size() { return false }
        for i = 0; i < len; i++ {
            if self[i] != other[i] {
                return false
            }
        }
        true
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
}
