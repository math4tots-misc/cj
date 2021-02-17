package cj

class Default_ {
    def __new[T: Default](): T = T.default()
}
