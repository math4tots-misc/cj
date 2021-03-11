package cj

import cj.ArrayBuffer
import cj.ArrayBufferView
import cj.Collection

## In Javascript, wraps Int8Array
native class Int8Array : Collection[Int], Default, Repr, Default, ArrayBufferView {
    def(list: List[Int]): Self
    def withSize(n: Int): Self
    def fromIterable[C: Iterable[Int]](c: C): Self
    def iter(self: Self): Iterator[Int]
    def size(self: Self): Int
    def __getitem(self: Self, i: Int): Int
    def __setitem(self: Self, i: Int, v: Int)
    def default(): Self
    def __get_byteLength(self): Int
    def __get_byteOffset(self): Int
    def __get_buffer(self: Self): ArrayBuffer
    def repr(self): String
}
