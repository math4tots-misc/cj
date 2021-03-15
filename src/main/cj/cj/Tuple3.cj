package cj

import cj.Math

native class Tuple3[A0?, A1?, A2?]:
        Eq if A0 : Eq and A1 : Eq and A2 : Eq,
        Ord if A0 : Ord and A1 : Ord and A2 : Ord,
        Hash if A0 : Hash and A1 : Hash and A2 : Hash,
        Repr if A0 : Repr and A1 : Repr and A2 : Repr {
    @generic def __get_f0(self): A0 = js!(A0, self, "[0]")
    @generic def __get_f1(self): A1 = js!(A1, self, "[1]")
    @generic def __get_f2(self): A2 = js!(A2, self, "[2]")
    if A0 : Eq and A1 : Eq and A2 : Eq def __eq(self: Self, other: Self): Bool = self is other or (
        f0 == other.f0 and
        f1 == other.f1 and
        f2 == other.f2)
    if A0 : Ord and A1 : Ord and A2 : Ord def __lt(self: Self, other: Self): Bool = (
        f0 < other.f0 or f0 <= other.f0 and (
            f1 < other.f1 or f1 <= other.f1 and (
                f2 < other.f2)))
    if A0 : Hash and A1 : Hash and A2 : Hash def hash(self: Self): Int = (
        Math.combineHash(Math.combineHash(
            f0.hash(), f1.hash()), f2.hash()))
    if A0 : Repr and A1 : Repr and A2 : Repr def repr(self: Self): String = (
        "(" + f0.repr() + ", " + f1.repr() + ", " + f2.repr() + ")")
}
