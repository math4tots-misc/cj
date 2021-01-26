package cj

import cj.ArrayBufferView
import cj.ToArrayBufferView
import cj.Collection

native class Float32Array : Collection[Double], ToArrayBufferView {
    @variadic def new(list: List[Double]): Self
    def withSize(n: Int): Self
    def fromIterable[C: Iterable[Double]](c: C): Self
    def iter(self: Self): Iterator[Double]
    def size(self: Self): Int
    def __getitem(self: Self, i: Int): Double
    def __setitem(self: Self, i: Int, v: Double)

    def toArrayBufferView(self: Self) : ArrayBufferView
}
