package cj

import cj.Float32Array
import cj.Approximate
import cj.ArrayBufferView
import cj.ToArrayBufferView
import cj.Collection

## On Javascript targets, wraps Float64Array
native class Float64Array : Collection[Double], ToArrayBufferView, Hash, Approximate, Repr, Default {
    @variadic def new(list: List[Double]): Self
    def withSize(n: Int): Self
    def fromIterable[C: Iterable[Double]](c: C): Self
    def iter(self: Self): Iterator[Double]
    def size(self: Self): Int
    def __getitem(self: Self, i: Int): Double
    def __setitem(self: Self, i: Int, v: Double)
    def __slice(self: Self, start: Int, end: Int): Self
    def __sliceFrom(self: Self, start: Int): Self
    def __sliceTo(self: Self, end: Int): Self

    def toArrayBufferView(self: Self) : ArrayBufferView

    def map(self: Self, f: Fn[Double, Double]): Self

    def clone(self: Self): Self

    def hash(self: Self): Int
    def __eq(self: Self, other: Self): Bool
    def approximates(self: Self, other: Self, tolerance: Double): Bool
    def repr(self: Self): String

    def scale(self: Self, factor: Double)
    def addWithFactor(self: Self, other: Self, factor: Double)

    def toFloat32Array(self): Float32Array

    def default(): Self
}
