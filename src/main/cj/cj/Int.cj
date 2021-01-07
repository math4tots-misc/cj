package cj

native class Int: Repr, Hash, Ord {
    def repr(self: Self): String
    def __eq(self: Self, other: Self): Bool
    def hash(self: Self): Int
    def __add(a: Self, b: Self): Int
    def __sub(a: Self, b: Self): Int
    def __mul(a: Self, b: Self): Int
    def __mod(a: Self, b: Self): Int
    def toBool(self: Self): Bool
    def __lt(self: Self, other: Self): Bool
}
