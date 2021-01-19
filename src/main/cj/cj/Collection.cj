package cj

trait Collection[T?] : Iterable[T], ToBool {
    def size(self: Self): Int
    def isEmpty(self: Self): Bool = self.size() == 0
    def toBool(self: Self): Bool = not self.isEmpty()
}
