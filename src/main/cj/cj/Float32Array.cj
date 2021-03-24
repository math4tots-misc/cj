package cj

import cj.NativeArrayLike
import cj.ArrayBufferView
import cj.ArrayBuffer
import cj.Float64Array
import cj.Approximate

## On Javascript targets, wraps Float32Array
native class Float32Array : NativeArrayLike[Double], Hash, Approximate, Repr, Default, ArrayBufferView {
    def(list: List[Double]): Self = js!(Self, "new Float32Array(", list, ")")
    def withSize(n: Int): Self = js!(Self, "new Float32Array(", n, ")")
    def fromIterable[C: Iterable[Double]](c: C): Self = js!(
        Self, "new Float32Array(", c.iter(), ")")
    def map(self: Self, f: Fn[Double, Double]): Self = fromIterable(iter().map(f))
    def clone(self: Self): Self = js!(Self, "new Float32Array(", self, ")")
    def default(): Self = js!(Self, "new Float32Array()")
    def repr(self: Self): String = "Float32Array(" + toList() + ")"
    def scale(self: Self, factor: Double) {
        for i = 0; i < size(); i++ {
            self[i] = factor * self[i]
        }
    }
    def addWithFactor(self: Self, other: Self, factor: Double) {
        for i = 0; i < size(); i++ {
            self[i] = self[i] + factor * other[i]
        }
    }
    def toFloat64Array(self): Float64Array = js!(Float64Array, "new Float64Array(", self, ")")
}
