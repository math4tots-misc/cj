package cj

import cj.Float64Array
import cj.Approximate
import cj.ArrayBufferView
import cj.ToArrayBufferView
import cj.Collection

## On Javascript targets, wraps Float32Array
native class Float32Array : Collection[Double], ToArrayBufferView, Hash, Approximate, Repr, Default {
    @variadic def(list: List[Double]): Self
    def withSize(n: Int): Self
    def fromIterable[C: Iterable[Double]](c: C): Self
    def iter(self: Self): Iterator[Double]
    def size(self: Self): Int
    def __getitem(self: Self, i: Int): Double
    def __setitem(self: Self, i: Int, v: Double)

    def toArrayBufferView(self: Self) : ArrayBufferView

    def map(self: Self, f: Fn[Double, Double]): Self

    def clone(self: Self): Self

    def hash(self: Self): Int
    def __eq(self: Self, other: Self): Bool
    def approximates(self: Self, other: Self, tolerance: Double): Bool
    def repr(self: Self): String

    def scale(self: Self, factor: Double)
    def addWithFactor(self: Self, other: Self, factor: Double)

    def toFloat64Array(self): Float64Array

    def default(): Self
}
