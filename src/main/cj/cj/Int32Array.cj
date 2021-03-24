package cj

import cj.NativeArrayLike
import cj.ArrayBufferOrView
import cj.ArrayBuffer
import cj.ArrayBufferView

## In Javascript, wraps Int32Array
native class Int32Array : NativeArrayLike[Int], Default, Repr, Default, ArrayBufferView {

    @implicit(List, fromList)
    @implicit(ArrayBufferOrView, _jsctor)
    class Convertible {
        val x: Int32Array
        def fromList(list: List[Int]): Self = js!(Self, "new Int32Array(", list, ")")
        @generic def _jsctor[T](t: T): Self = js!(Self, "new Int32Array(", t, ")")
    }

    def(conv: Convertible): Self = conv.x
    def withSize(n: Int): Self = js!(Self, "new Int32Array(", n, ")")
    def fromIterable[C: Iterable[Int]](c: C): Self = js!(
        Self, "new Int32Array(", c.iter(), ")")
    def map(self: Self, f: Fn[Int, Int]): Self = fromIterable(iter().map(f))
    def clone(self: Self): Self = js!(Self, "new Int32Array(", self, ")")
    def default(): Self = js!(Self, "new Int32Array()")
    def repr(self: Self): String = "Int32Array(" + toList() + ")"
}
