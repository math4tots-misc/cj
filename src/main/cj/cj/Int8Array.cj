package cj

import cj.NativeArrayLike
import cj.ArrayBuffer
import cj.ArrayBufferView
import cj.Collection

## In Javascript, wraps Int8Array
native class Int8Array : NativeArrayLike[Int], Default, Repr, Default, ArrayBufferView {
    def(list: List[Int]): Self = js!(Self, "new Int8Array(", list, ")")
    def withSize(n: Int): Self = js!(Self, "new Int8Array(", n, ")")
    def fromIterable[C: Iterable[Int]](c: C): Self = js!(
        Self, "new Int8Array(", c.iter(), ")")
    def map(self: Self, f: Fn[Int, Int]): Self = fromIterable(iter().map(f))
    def clone(self: Self): Self = js!(Self, "new Int8Array(", self, ")")
    def default(): Self = js!(Self, "new Int8Array()")
    def repr(self: Self): String = "Int8Array(" + toList() + ")"
}
