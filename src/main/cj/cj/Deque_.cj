package cj

import cj.Deque

class Deque_ {
    @variadic def[T](list: List[T]): Deque[T] = Deque[T].fromList(list)
}
