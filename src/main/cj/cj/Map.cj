package cj

import cj.Range

class Map[K: Hash, V] {
    var _size : Int
    var _list : List[List[Tuple[K, V]]]

    def empty(): Self = Self.__malloc(0, [])

    def _rehash(self: Self, newCap: Int) = {
        if self._list.size() < newCap {
            val oldList = self._list
            self._size = 0
            self._list = Range.upto(newCap).iter().map(i -> List[Tuple[K, V]].empty()).toList()
        }
    }

    def size(self: Self): Int = self._size
}
