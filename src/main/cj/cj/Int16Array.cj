package cj

import cj.ArrayBufferView
import cj.ToArrayBufferView
import cj.Collection

## In Javascript, wraps Int16Array
native class Int16Array : Collection[Int], Default, ToArrayBufferView {
    @variadic def new(list: List[Int]): Self
    def fromIterable[C: Iterable[Int]](c: C): Self
    def iter(self: Self): Iterator[Int]
    def size(self: Self): Int
    def __getitem(self: Self, i: Int): Int
    def __setitem(self: Self, i: Int, v: Int)
    def default(): Self
    def toArrayBufferView(self: Self): ArrayBufferView
}
