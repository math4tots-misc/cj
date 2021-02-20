package cj

import cj.ToList

trait Iterable[T?]: ToList[T] {
    def iter(self: Self): Iterator[T]
    def toList(self: Self): List[T] = self.iter().toList()
    if T: Hash def toSet(self: Self): Set[T] = {
        val set = Set[T].empty()
        for t in self {
            set.add(t)
        }
        set
    }
    def toMap[K?: Hash, V?, C: Iterable[Tuple[K, V]]](self: C): Map[K, V] = {
        val map = Map[K, V].empty()
        for (k, v) in self {
            map[k] = v
        }
        map
    }

    def fold[R](self: Self, var r: R, f: Fn[R, T, R]): R = {
        for t in self {
            r = f.call(r, t)
        }
        r
    }

    def reduce(self: Self, f: Fn[T, T, T]): T = {
        val iter = self.iter()
        var ret = iter.nextOrElse(() -> IO.panic("reduce on an empty Iterable"))
        for t in iter {
            ret = f.call(ret, t)
        }
        ret
    }

    if T : Ord def sorted(self): List[T] = {
        val list = toList()
        list.sort()
        list
    }
    def sortedBy[X: Ord](self, f: Fn[T, X]): List[T] {
        val list = toList()
        list.sortBy(f)
        list
    }
    if T : Ord def min(self: Self): T = self.reduce((a, b) -> if a < b { a } else { b })
    if T : Ord def max(self: Self): T = self.reduce((a, b) -> if a < b { b } else { a })
}
