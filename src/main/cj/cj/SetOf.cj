package cj

class SetOf {
    @variadic def[T?: Hash](ts: List[T]): Set[T] = Set[T](ts)
}
