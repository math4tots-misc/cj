package cj

import cj.FromAny

native class JSON : FromAny, Repr, Eq {

    union Type {
        case number # 0
        case string # 1
        case bool # 2
        case nil # 3
        case array # 4
        case object # 5
    }

    def parse(string: String): JSON

    @variadic def object(pairs: List[Tuple[String, JSON]]): JSON

    def fromAny[T](t: T): Self
    def __getitem(self: Self, key: Self): Self
    def __setitem(self: Self, key: Self, value: Self)
    def repr(self: Self): String
    def type(self: Self): Type

    def __eq(self: Self, other: Self): Bool
}
