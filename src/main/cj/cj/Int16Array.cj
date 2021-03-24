package cj

import cj.NativeArrayLike
import cj.ArrayBuffer
import cj.ArrayBufferView

## In Javascript, wraps Int16Array
native class Int16Array : NativeArrayLike[Int], Default, Repr, Default, ArrayBufferView {
    def(list: List[Int]): Self = js!(Self, "new Int16Array(", list, ")")
    def withSize(n: Int): Self = js!(Self, "new Int16Array(", n, ")")
    def fromIterable[C: Iterable[Int]](c: C): Self = js!(
        Self, "new Int16Array(", c.iter(), ")")
    def map(self: Self, f: Fn[Int, Int]): Self = fromIterable(iter().map(f))
    def clone(self: Self): Self = js!(Self, "new Int16Array(", self, ")")
    def default(): Self = js!(Self, "new Int16Array()")
    def repr(self: Self): String = "Int16Array(" + toList() + ")"
}
