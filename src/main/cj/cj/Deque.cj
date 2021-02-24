package cj

import cj.Error
import cj.Collection

class Deque[T?] :
        Collection[T],
        Default,
        Eq if T : Eq,
        Hash if T : Hash,
        Repr if T : Repr {
    var list: List[T]
    var start: Int = 0

    @generic def empty(): Self = __malloc([])
    @variadic @generic def(list: List[T]): Self = __malloc(list)
    @generic def fromList(list: List[T]): Self = __malloc(list)
    def fromIterator(iterator: Iterator[T]): Self = fromList(iterator.toList())

    def iter(self): Iterator[T] = list.iterFrom(start)
    def size(self): Int = list.size() - start
    @generic def add(self, t: T) = list.add(t)
    @genericSelf def addAll[C: Iterable[T]](self, c: C) = list.addAll(c)
    def addleft(self, t: T) {
        if start == 0 {
            val newList = List[T]._clearListWithSize(if list.isEmpty() { 2 } else { list.size() })
            start = newList.size()
            newList.addAll(list)
            list = newList
        }
        start = start - 1
        list[start] = t
    }
    def pop(self): T = {
        if start == list.size() {
            throw Error("pop from empty deque")
        }
        list.pop()
    }
    def popleft(self): T {
        if start == list.size() {
            throw Error("popleft from empty deque")
        }
        val t = list[start]
        list._clearItem(start)
        start = start + 1
        t
    }
    def __add(self, other: Self): Self {
        val ret = empty()
        ret.addAll(self)
        ret.addAll(other)
        ret
    }
    def __getitem(self, i: Int): T = list[i - start]
    def __setitem(self, i: Int, t: T) = { list[i - start] = t }
    def last(self): T = list.last()
    def swap(self, i: Int, j: Int) = list.swap(i - start, j - start)
    def __slice(self, a: Int, b: Int): Self = __malloc(list[a - start:b - start])
    def __sliceFrom(self, a: Int): Self = __malloc(list[a - start:])
    def __sliceTo(self, b: Int): Self = __malloc(list[:b - start])
    def __mul(self, n: Int): Self = __malloc(list[start:] * n)

    def map[R?](self, f: Fn[T, R]): Deque[R] = Deque[R].fromIterator(iter().map(f))
    def filter(self, f: Fn[T, Bool]): Self = fromIterator(iter().filter(f))
    def clone(self): Self = __malloc(list[start:])

    def default(): Self = empty()

    if T : Eq def __contains(self, t: T): Bool {
        for i = start; i < list.size(); i++ {
            if list[i] == t {
                return true
            }
        }
        false
    }
    if T : Eq def __eq(self, other: Self): Bool = list[start:] == other.list[other.start:]
    if T : Hash def hash(self): Int = list[start:].hash()
    if T : Repr def repr(self): String = "Deque(" + ", ".join(self.map(t -> t.repr())) + ")"
}
