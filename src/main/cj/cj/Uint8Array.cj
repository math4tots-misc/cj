package cj

import cj.BufferLike
import cj.NativeArrayLike
import cj.ArrayBufferOrView
import cj.ArrayBuffer
import cj.ArrayBufferView
import cj.Collection

## In Javascript, wraps Uint8Array
native class Uint8Array : NativeArrayLike[Int], Default, Repr, Default, ArrayBufferView {

    @implicit(List, fromList)
    @implicit(ArrayBufferOrView, _jsctor)
    class Convertible {
        val x: Uint8Array
        def fromList(list: List[Int]): Self = js!(Self, "new Uint8Array(", list, ")")
        @generic def _jsctor[T](t: T): Self = js!(Self, "new Uint8Array(", t, ")")
    }

    def(conv: Convertible): Self = conv.x
    def fromParts(buffer: ArrayBuffer, byteOffset: Int, byteLength: Int): Self = js!(
        Self, "new Uint8Array(", buffer, ",", byteOffset, ",", byteLength, ")")
    def withSize(n: Int): Self = js!(Self, "new Uint8Array(", n, ")")
    def fromIterable[C: Iterable[Int]](c: C): Self = js!(
        Self, "new Uint8Array(", c.iter(), ")")
    def map(self: Self, f: Fn[Int, Int]): Self = fromIterable(iter().map(f))
    def clone(self: Self): Self = js!(Self, "new Uint8Array(", self, ")")
    def default(): Self = js!(Self, "new Uint8Array()")
    def repr(self: Self): String = "Uint8Array(" + toList() + ")"

    def set[B: BufferLike](self, other: B, offset: Int) = js!(
        Unit, self, ".set(", other.asUint8Array(), ",", offset, ")")
}
