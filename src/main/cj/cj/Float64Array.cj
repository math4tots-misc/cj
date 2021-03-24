package cj

import cj.NativeArrayLike
import cj.ArrayBufferView
import cj.ArrayBuffer
import cj.Float32Array
import cj.Approximate

## On Javascript targets, wraps Float64Array
native class Float64Array : NativeArrayLike[Double], Hash, Approximate, Repr, Default, ArrayBufferView {
    def(list: List[Double]): Self = js!(Self, "new Float64Array(", list, ")")
    def withSize(n: Int): Self = js!(Self, "new Float64Array(", n, ")")
    def fromIterable[C: Iterable[Double]](c: C): Self = js!(
        Self, "new Float64Array(", c.iter(), ")")
    def map(self: Self, f: Fn[Double, Double]): Self = fromIterable(iter().map(f))
    def clone(self: Self): Self = js!(Self, "new Float64Array(", self, ")")
    def default(): Self = js!(Self, "new Float64Array()")
    def repr(self: Self): String = "Float64Array(" + toList() + ")"
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
    def toFloat32Array(self): Float32Array = js!(Float32Array, "new Float32Array(", self, ")")
}
