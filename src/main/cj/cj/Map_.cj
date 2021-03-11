package cj

## Untyped companion class for Map
class Map_ {
    @generic def empty[K?: Hash, V?](): Map[K, V] = Map[K, V].empty()

    def of[K?: Hash, V?](pairs: List[Tuple[K, V]]): Map[K, V] = Map[K, V].of(pairs)

    def __new[K?: Hash, V?](pairs: List[Tuple[K, V]]): Map[K, V] = Self.of(pairs)
}
