package cj

class Map[K: Hash, V] {
    var _size : Int
    var _list : List[List[Tuple[K, V]]]

    def size(self: Self): Int = self._size
}
