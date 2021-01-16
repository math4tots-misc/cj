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
}
