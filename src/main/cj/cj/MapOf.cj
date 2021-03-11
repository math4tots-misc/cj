package cj

class MapOf {
    @variadic def[K?: Hash, V?](pairs: List[Tuple[K, V]]): Map[K, V] = Map[K, V](pairs)
}
