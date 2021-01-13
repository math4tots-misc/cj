package cj

import cj.ToList

trait Iterable[T?]: ToList[T] {
    def iter(self: Self): Iterator[T]
    def toList(self: Self): List[T] = self.iter().toList()
}
