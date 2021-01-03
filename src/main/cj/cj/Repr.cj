package cj

trait Repr: ToString {
    def repr(self: Self): String
    def toString(self: Self): String = Self.repr(self)
}
