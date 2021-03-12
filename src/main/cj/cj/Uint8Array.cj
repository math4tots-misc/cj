package cj

import cj.ArrayBufferOrView
import cj.ArrayBuffer
import cj.ArrayBufferView
import cj.Collection

## In Javascript, wraps Uint8Array
native class Uint8Array : Collection[Int], Default, Repr, Default, ArrayBufferView {

    @implicit(List, fromList)
    @implicit(ArrayBufferOrView, _jsctor)
    class Convertible {
        val x: Uint8Array
        def fromList(list: List[Int]): Self = js!(Self, "new Uint8Array(", list, ")")
        @generic def _jsctor[T](t: T): Self = js!(Self, "new Uint8Array(", t, ")")
    }

    def(conv: Convertible): Self = conv.x
    def fromParts(buffer: ArrayBuffer, byteOffset: Int, byteLength: Int): Self
    def withSize(n: Int): Self
    def fromIterable[C: Iterable[Int]](c: C): Self
    def iter(self: Self): Iterator[Int]
    def size(self: Self): Int
    def __getitem(self: Self, i: Int): Int
    def __setitem(self: Self, i: Int, v: Int)
    def default(): Self
    def repr(self): String
}
