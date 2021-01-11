package cj

## The nullable type
##
## This type is treated specially by the compiler.
## In particular, a nullable type may never appear as a type argument.
##
## TODO: Allow Nullable to appear as a type argument in a way similar to Rust's "?Sized" mechanism.
##
@nullable
native class Nullable[T] {
    def isPresent(self: Self): Bool
    def isEmpty(self: Self): Bool
    def map[R](self: Self, f: Fn[T, R]): Nullable[R]
    def get(self: Self): T
}
