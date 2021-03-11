package cj

import cj.Math

native class Tuple3[A0?, A1?, A2?]:
        Eq if A0 : Eq and A1 : Eq and A2 : Eq,
        Ord if A0 : Ord and A1 : Ord and A2 : Ord,
        Hash if A0 : Hash and A1 : Hash and A2 : Hash,
        Repr if A0 : Repr and A1 : Repr and A2 : Repr {
    @generic def get0(self: Self): A0
    @generic def get1(self: Self): A1
    @generic def get2(self: Self): A2
    if A0 : Eq and A1 : Eq and A2 : Eq def __eq(self: Self, other: Self): Bool = self is other or (
        get0() == other.get0() and
        get1() == other.get1() and
        get2() == other.get2())
    if A0 : Ord and A1 : Ord and A2 : Ord def __lt(self: Self, other: Self): Bool = (
        get0() < other.get0() or get0() <= other.get0() and (
            get1() < other.get1() or get1() <= other.get1() and (
                get2() < other.get2())))
    if A0 : Hash and A1 : Hash and A2 : Hash def hash(self: Self): Int = (
        Math.combineHash(Math.combineHash(
            get0().hash(), get1().hash()), get2().hash()))
    if A0 : Repr and A1 : Repr and A2 : Repr def repr(self: Self): String = (
        "(" + get0().repr() + ", " + get1().repr() + ", " + get2().repr() + ")")
}
