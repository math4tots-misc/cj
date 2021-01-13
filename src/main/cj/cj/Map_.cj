package cj

## Untyped companion class for Map
class Map_ {
    def empty[K: Hash, V?](): Map[K, V] = Map[K, V].empty()

    def of[K: Hash, V?](pairs: List[Tuple[K, V]]): Map[K, V] = {
        val ret = Map[K, V].empty()
        for (k, v) in pairs {
            ret.set(k, v)
        }
        ret
    }
}
