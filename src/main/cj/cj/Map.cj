package cj

import cj.NonNull
import cj.Range

class Map[K?: Hash, V?] :
        Default,
        Eq if V : Eq,
        Hash if V : Hash,
        Repr if K : Repr and V : Repr {
    var _size : Int
    var _list : List[List[Tuple[Int, K, V]]]

    @generic def empty(): Self = Self.__malloc(0, [])

    @generic def default(): Self = Self.empty()

    def of(pairs: List[Tuple[K, V]]): Self = {
        val ret = Self.empty()
        for (k, v) in pairs {
            ret[k] = v
        }
        ret
    }

    @variadic
    def(pairs: List[Tuple[K, V]]): Self = Self.of(pairs)

    def clone(self): Self = of(pairs().toList())

    def _rehash(self: Self, newCap: Int) = {
        if self._list.size() < newCap {
            val oldList = self._list
            self._size = 0
            self._list = List.ofSize(newCap, i -> [])
            for bucket in oldList {
                for triple in bucket {
                    self._insertNoRehash(triple)
                }
            }
        }
    }

    def _insertNoRehash(self: Self, triple: Tuple[Int, K, V]) = {
        val hash = triple.get0()
        val key = triple.get1()
        val list = self._list
        val index = Self._getIndex(hash, list.size())
        val bucket = list[index]
        for i = 0; i < bucket.size(); i++ {
            val entry = bucket[i]
            if hash == entry.get0() and entry.get1() == key {
                bucket[i] = triple
                return ()
            }
        }
        self._size += 1
        bucket.add(triple)
    }

    def _checkForRehashBeforeInsert(self: Self) = {
        if self._list.isEmpty() {
            self._rehash(16)
        } else if 4 * self._size >= 3 * self._list.size() {
            self._rehash(self._list.size() * 2)
        }
    }

    @generic def size(self: Self): Int = self._size

    def addAll[C: Iterable[Tuple[K, V]]](self, pairs: C) {
        for (k, v) in pairs {
            self[k] = v
        }
    }

    def __setitem(self: Self, key: K, value: V) = {
        self._checkForRehashBeforeInsert()
        val hash = key.hash()
        self._insertNoRehash((hash, key, value))
    }

    def _getTriple(self: Self, key: K): Nullable[Tuple[Int, K, V]] = self._getTripleWithHash(key, key.hash())

    def _getTripleWithHash(self: Self, key: K, hash: Int): Nullable[Tuple[Int, K, V]] = {
        if self._size == 0 {
            return null
        }
        val list = self._list
        val index = Self._getIndex(hash, list.size())
        val bucket = list[index]
        for triple in bucket {
            if triple.get0() == hash and triple.get1() == key {
                return null(triple)
            }
        }
        return null
    }

    def getOrInsert(self: Self, key: K, f: Fn[V]): V = {
        if null(triple) = self._getTriple(key) {
            triple.get2()
        } else {
            val value = f.call()
            self[key] = value
            value
        }
    }

    def getOrDefault(self: Self, key: K, d: V): V = (
        if null(t) = self._getTriple(key) { t.get2() } else { d })

    def getOrElse(self: Self, key: K, f: Fn[V]): V = (
        if null(t) = self._getTriple(key) { t.get2() } else { f.call() })

    if V : NonNull def getOrNull(self: Self, key: K) : Nullable[V] = (
        if null(t) = self._getTriple(key) { null(t.get2()) } else { null })

    def __contains(self: Self, key: K): Bool = self._getTriple(key).isPresent()

    def __getitem(self: Self, key: K): V = self._getTriple(key).get().get2()

    def __add(self: Self, other: Self): Self = {
        val ret = Self.empty()
        for (k, v) in self.pairs() {
            ret[k] = v
        }
        for (k, v) in other.pairs() {
            ret[k] = v
        }
        ret
    }

    def _removeTriple(self: Self, key: K): Nullable[Tuple[Int, K, V]] = {
        if self._list.isEmpty() {
            return null
        }
        val hash = key.hash()
        val index = Self._getIndex(hash, self._list.size())
        val bucket = self._list[index]
        for i = 0; i < bucket.size(); i++ {
            val triple = bucket[i]
            if triple.get0() == hash and triple.get1() == key {
                self._size += -1
                return null(bucket.removeIndex(i))
            }
        }
        return null
    }

    def removeOrFalse(self: Self, key: K): Bool = self._removeTriple(key).isPresent()

    if V : NonNull def remove(self: Self, key: K): Nullable[V] = self._removeTriple(key).map(t -> t.get2())

    if K : Repr def removeOrThrow(self: Self, key: K) = {
        if self._removeTriple(key).isEmpty() {
            IO.panic("Key " + key.repr() + " not found in this map")
        }
    }

    def keys(self: Self): Iterator[K] = (
        self._list.iter().flatMap(bucket -> bucket.map(triple -> triple.get1())))

    def values(self: Self): Iterator[V] = (
        self._list.iter().flatMap(bucket -> bucket.map(triple -> triple.get2())))

    def pairs(self: Self): Iterator[Tuple[K, V]] = (
        self._list.iter().flatMap(bucket -> bucket.map(triple -> (triple.get1(), triple.get2()))))

    def _getIndex(hash: Int, size: Int) : Int = (hash % size + size) % size

    if V: Eq def __eq(self: Self, other: Self): Bool = {
        if self._size != other._size {
            return false
        } else if self._size == 0 {
            return true
        }
        for (hash, k, v) in self._list.iter().flatMap(bucket -> bucket) {
            if null((_h, _k, otherV)) = other._getTripleWithHash(k, hash) {
                if v != otherV {
                    return false
                }
            } else {
                return false
            }
        }
        true
    }

    if V: Hash def hash(self: Self): Int = (
        self.pairs().fold(0, (h, pair) -> h + pair.hash()))

    if K: Repr and V: Repr def repr(self: Self): String = (
        "Map(" +
        ", ".join(self.pairs().map(kv -> kv.get0().repr() + ": " + kv.get1().repr())) +
        ")")
}
