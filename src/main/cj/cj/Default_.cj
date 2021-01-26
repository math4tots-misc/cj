package cj

class Default_ {
    def new[T: Default](): T = T.default()
}
