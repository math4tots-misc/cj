package cj

import cj.ArrayBufferView
import cj.ToArrayBufferView
import cj.Collection

## In Javascript, wraps Int32Array
native class Int32Array : Collection[Int], Default, ToArrayBufferView, Repr, Default {
    @variadic def(list: List[Int]): Self
    def withSize(n: Int): Self
    def fromIterable[C: Iterable[Int]](c: C): Self
    def iter(self: Self): Iterator[Int]
    def size(self: Self): Int
    def __getitem(self: Self, i: Int): Int
    def __setitem(self: Self, i: Int, v: Int)
    def default(): Self
    def asArrayBufferView(self: Self): ArrayBufferView
    def repr(self): String
}
