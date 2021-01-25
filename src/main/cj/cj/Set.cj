package cj

import cj.Collection

class Set[T?: Hash] :
        Collection[T],
        Default,
        Hash,
        Repr if T : Repr {
    val _map : Map[T, T]

    @generic def empty(): Self = Self.__malloc(Map.empty())

    @generic def default(): Self = Self.empty()

    def of(ts: List[T]): Self = {
        val ret = Self.empty()
        for t in ts {
            ret.add(t)
        }
        ret
    }

    @variadic
    def new(ts: List[T]): Self = Set.of(ts)

    def size(self: Self): Int = self._map.size()

    def add(self: Self, t: T) = self._map[t] = t

    def addAll[C: Iterable[T]](self: Self, ts: C) = {
        for t in ts {
            self.add(t)
        }
    }

    def removeOrFalse(self: Self, t: T): Bool = self._map.removeOrFalse(t)

    if T : NonNull def remove(self: Self, t: T): Nullable[T] = self._map.remove(t)

    if T : Repr def removeOrThrow(self: Self, t: T) = self._map.removeOrThrow(t)

    def iter(self: Self): Iterator[T] = self._map.keys()

    def __eq(self: Self, other: Self): Bool = self._map == other._map

    def hash(self: Self): Int = self.iter().fold(0, (h, t) -> h + t.hash())

    if T : Repr def repr(self: Self): String = {
        "Set(" + ", ".join(self.iter().map(t -> t.repr())) + ")"
    }

    def __contains(self: Self, t: T): Bool = t in self._map

    def __add(self: Self, other: Self): Self = {
        val ret = Self.empty()
        for t in self {
            ret.add(t)
        }
        for t in other {
            ret.add(t)
        }
        return ret
    }

    def filter(self: Self, f: Fn[T, Bool]): Set[T] = {
        val set = Self.empty()
        for t in self {
            if f.call(t) {
                set.add(t)
            }
        }
        set
    }

    def flatMap[X?: Hash, C: Iterable[X]](self: Self, f: Fn[T, C]): Set[X] = {
        val set = Set[X].empty()
        for t in self {
            for x in f.call(t) {
                set.add(x)
            }
        }
        set
    }
}
