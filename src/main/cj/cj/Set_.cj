package cj

class Set_ {
    @generic def empty[T?: Hash](): Set[T] = Set[T].empty()

    def of[T?: Hash](ts: List[T]): Set[T] = Set[T].of(ts)

    @variadic
    def new[T?: Hash](ts: List[T]): Set[T] = Self.of(ts)
}
