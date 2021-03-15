package cj

import cj.Math

native class Tuple2[A0?, A1?]:
        Eq if A0 : Eq and A1 : Eq,
        Ord if A0 : Ord and A1 : Ord,
        Hash if A0 : Hash and A1 : Hash,
        Repr if A0 : Repr and A1 : Repr {
    @generic def __get_f0(self): A0 = js!(A0, self, "[0]")
    @generic def __get_f1(self): A1 = js!(A1, self, "[1]")
    if A0 : Eq and A1 : Eq def __eq(self: Self, other: Self): Bool = self is other or (
        f0 == other.f0 and
        f1 == other.f1)
    if A0 : Ord and A1 : Ord def __lt(self: Self, other: Self): Bool = (
        f0 < other.f0 or f0 <= other.f0 and (
            f1 < other.f1))
    if A0 : Hash and A1 : Hash def hash(self: Self): Int = Math.combineHash(
        f0.hash(),
        f1.hash())
    if A0 : Repr and A1 : Repr def repr(self: Self): String = (
        "(" + f0.repr() + ", " + f1.repr() + ")")
}
