package cj

## The nullable type
##
## This type is treated specially by the compiler.
## In particular, a nullable type may never appear as a type argument.
##
@nullable
native class Nullable[T]: Iterable[T], ToBool, Default, Eq if T: Eq, Repr if T: Repr {
    @generic def isPresent(self: Self): Bool
    @generic def isEmpty(self: Self): Bool
    @generic def map[R](self: Self, f: Fn[T, R]): Nullable[R]
    @generic def get(self: Self): T
    @generic def iter(self: Self): Iterator[T]
    @generic def toBool(self: Self): Bool
    @generic def default(): Self
    if T : Eq def __eq(self: Self, other: Self): Bool {
        if val a = self {
            if val b = other {
                return a == b
            }
        }
        false
    }
    if T : Repr def repr(self: Self): String {
        if val x = self { "null(" + x.repr() + ")" } else { "null" }
    }
}
