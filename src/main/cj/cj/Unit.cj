package cj

native class Unit : Hash, Repr {
    def __eq(self: Self, other: Self): Bool = true
    def hash(self: Self): Int = 38201
    def repr(self: Self): String = "()"
}
