package cj

class Set_ {
    @generic def empty[T?: Hash](): Set[T] = Set[T].empty()

    def of[T?: Hash](ts: List[T]): Set[T] = Set[T].of(ts)

    def __new[T?: Hash](ts: List[T]): Set[T] = Self.of(ts)

    def fromIterable[T?: Hash, I: Iterable[T]](ts: I): Set[T] {
        val set = Set[T].empty()
        set.addAll(ts)
        set
    }
}
