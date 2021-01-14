package cj

class Set[T?: Hash] :
        Iterable[T],
        Hash,
        Repr if T : Repr {
    val _map : Map[T, T]

    @generic def empty(): Self = Self.__malloc(Map.empty())

    def of(ts: List[T]): Self = {
        val ret = Self.empty()
        for t in ts {
            ret.add(t)
        }
        ret
    }

    def add(self: Self, t: T) = self._map.set(t, t)

    def removeOrFalse(self: Self, t: T): Bool = self._map.removeOrFalse(t)

    if T : NonNull def remove(self: Self, t: T): Nullable[T] = self._map.remove(t)

    if T : Repr def removeOrThrow(self: Self, t: T) = self._map.removeOrThrow(t)

    def iter(self: Self): Iterator[T] = self._map.keys()

    def __eq(self: Self, other: Self): Bool = self._map == other._map

    def hash(self: Self): Int = self.iter().fold(0, (h, t) -> h + t.hash())

    if T : Repr def repr(self: Self): String = {
        "Set(" + ", ".join(self.iter().map(t -> t.repr())) + ")"
    }
}
