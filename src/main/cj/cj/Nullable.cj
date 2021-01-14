package cj

## The nullable type
##
## This type is treated specially by the compiler.
## In particular, a nullable type may never appear as a type argument.
##
## TODO: Allow Nullable to appear as a type argument in a way similar to Rust's "?Sized" mechanism.
##
@nullable
native class Nullable[T]: Iterable[T], ToBool, Eq if T: Eq, Repr if T: Repr {
    @generic def isPresent(self: Self): Bool
    @generic def isEmpty(self: Self): Bool
    @generic def map[R](self: Self, f: Fn[T, R]): Nullable[R]
    @generic def get(self: Self): T
    @generic def iter(self: Self): Iterator[T]
    @generic def toBool(self: Self): Bool
    if T : Eq def __eq(self: Self, other: Self): Bool
    if T : Repr def repr(self: Self): String
}
