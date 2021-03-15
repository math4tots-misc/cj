package cj

import cj.Math

native class Tuple2[A0?, A1?]:
        Eq if A0 : Eq and A1 : Eq,
        Ord if A0 : Ord and A1 : Ord,
        Hash if A0 : Hash and A1 : Hash,
        Repr if A0 : Repr and A1 : Repr {
    @generic def get0(self: Self): A0
    @generic def get1(self: Self): A1
    @generic def __get_f0(self): A0 = js!(A0, self, "[0]")
    @generic def __get_f1(self): A1 = js!(A1, self, "[1]")
    if A0 : Eq and A1 : Eq def __eq(self: Self, other: Self): Bool = self is other or (
        get0() == other.get0() and
        get1() == other.get1())
    if A0 : Ord and A1 : Ord def __lt(self: Self, other: Self): Bool = (
        get0() < other.get0() or get0() <= other.get0() and (
            get1() < other.get1()))
    if A0 : Hash and A1 : Hash def hash(self: Self): Int = Math.combineHash(
        get0().hash(),
        get1().hash())
    if A0 : Repr and A1 : Repr def repr(self: Self): String = (
        "(" + get0().repr() + ", " + get1().repr() + ")")
}
