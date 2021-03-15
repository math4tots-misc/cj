package cj

import cj.Math

native class Tuple4[A0?, A1?, A2?, A3?]:
        Eq if A0 : Eq and A1 : Eq and A2 : Eq and A3 : Eq,
        Ord if A0 : Ord and A1 : Ord and A2 : Ord and A3 : Ord,
        Hash if A0 : Hash and A1 : Hash and A2 : Hash and A3 : Hash,
        Repr if A0 : Repr and A1 : Repr and A2 : Repr and A3 : Repr {
    @generic def get0(self: Self): A0
    @generic def get1(self: Self): A1
    @generic def get2(self: Self): A2
    @generic def get3(self: Self): A3
    @generic def __get_f0(self): A0 = js!(A0, self, "[0]")
    @generic def __get_f1(self): A1 = js!(A1, self, "[1]")
    @generic def __get_f2(self): A2 = js!(A2, self, "[2]")
    @generic def __get_f3(self): A3 = js!(A3, self, "[3]")
    if A0 : Eq and A1 : Eq and A2 : Eq and A3 : Eq def __eq(self: Self, other: Self): Bool = self is other or (
        get0() == other.get0() and
        get1() == other.get1() and
        get2() == other.get2() and
        get3() == other.get3())
    if A0 : Ord and A1 : Ord and A2 : Ord and A3 : Ord def __lt(self: Self, other: Self): Bool = (
        get0() < other.get0() or get0() <= other.get0() and (
            get1() < other.get1() or get1() <= other.get1() and (
                get2() < other.get2() or get2() <= other.get2() and (
                    get3() < other.get3()))))
    if A0 : Hash and A1 : Hash and A2 : Hash and A3 : Hash def hash(self: Self): Int = (
        Math.combineHash(Math.combineHash(Math.combineHash(
            get0().hash(), get1().hash()), get2().hash()), get3().hash()))
    if A0 : Repr and A1 : Repr and A2 : Repr and A3 : Repr def repr(self: Self): String = (
        "(" + get0().repr() + ", " + get1().repr() + ", " + get2().repr() + ", " + get3().repr() + ")")
}
