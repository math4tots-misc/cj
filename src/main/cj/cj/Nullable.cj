package cj

import cj.Error

## The nullable type
##
## This type is treated specially by the compiler.
## In particular, a nullable type may never appear as a type argument.
##
@nullable
native class Nullable[T]: Iterable[T], ToBool, Default, Eq if T: Eq, Repr if T: Repr {
    @generic def isPresent(self: Self): Bool = js!(Bool, self, "!==null")
    @generic def isEmpty(self: Self): Bool = js!(Bool, self, "===null")
    @generic def map[R](self, f: Fn[T, R]): Nullable[R] = if val t = self {
        null(f.call(t)) } else { null }
    @generic def get(self: Self): T {
        if js!(Bool, self, "===null") {
            throw Error("Get from empty Nullable")
        }
        js!(T, self)
    }
    @generic def getOr(self, t: T): T = if val r = self { r } else { t }
    @generic def iter(self): Iterator[T] = js!(Iterator[T], "nullIter(", self, ")")
    @generic def toBool(self: Self): Bool = isPresent()
    @generic def default(): Self = null
    if T : Eq def __eq(self: Self, other: Self): Bool {
        self is other or {
            if val a = self {
                if val b = other {
                    return a == b
                }
            }
            false
        }
    }
    if T : Repr def repr(self: Self): String {
        if val x = self { "null(" + x.repr() + ")" } else { "null" }
    }
}
