package cj

native class Tuple2[A0?, A1?]:
        Eq if A0 : Eq and A1 : Eq,
        Hash if A0 : Hash and A1 : Hash,
        Repr if A0 : Repr and A1 : Repr {
    @generic def get0(self: Self): A0
    @generic def get1(self: Self): A1
    if A0 : Eq and A1 : Eq def __eq(self: Self, other: Self): Bool
    if A0 : Hash and A1 : Hash def hash(self: Self): Int
    if A0 : Repr and A1 : Repr def repr(self: Self): String
}
