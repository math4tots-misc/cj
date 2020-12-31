package crossj.base;

public final class Map<K, V> {
    private int siz = 0;
    private List<List<Tuple3<Integer, K, V>>> list = null;
    private Map() {}

    @SafeVarargs
    public static <K, V> Map<K, V> of(Pair<K, V>... pairs) {
        Map<K, V> map = new Map<>();
        for (Pair<K, V> pair : pairs) {
            map.put(pair.get1(), pair.get2());
        }
        return map;
    }

    public static <K, V> Map<K, V> fromIterable(Iterable<Pair<K, V>> pairs) {
        Map<K, V> map = new Map<>();
        for (Pair<K, V> pair : pairs) {
            map.put(pair.get1(), pair.get2());
        }
        return map;
    }

    private void rehash(int newCap) {
        if (list == null || list.size() < newCap) {
            List<List<Tuple3<Integer, K, V>>> oldList = list;
            siz = 0;
            list = List.ofSize(newCap, () -> List.of());
            if (oldList != null) {
                for (List<Tuple3<Integer, K, V>> bucket : oldList) {
                    for (Tuple3<Integer, K, V> triple : bucket) {
                        insertNoRehash(triple);
                    }
                }
            }
        }
    }

    private void insertNoRehash(Tuple3<Integer, K, V> triple) {
        int hash = triple.get1();
        K key = triple.get2();
        int index = getIndex(hash, list.size());
        List<Tuple3<Integer, K, V>> bucket = list.get(index);
        for (int i = 0; i < bucket.size(); i++) {
            Tuple3<Integer, K, V> entry = bucket.get(i);
            if (hash == entry.get1() && entry.get2().equals(key)) {
                bucket.set(i, triple);
                return;
            }
        }
        siz++;
        bucket.add(triple);
    }

    private void checkForRehashBeforeInsert() {
        if (list == null || list.size() == 0) {
            rehash(16);
        } else if (4 * siz >= 3 * list.size()) {
            rehash(list.size() * 2);
        }
    }

    public int size() {
        return siz;
    }

    public void put(K key, V value) {
        checkForRehashBeforeInsert();
        int hash = key.hashCode();
        insertNoRehash(Tuple3.of(hash, key, value));
    }

    private Tuple3<Integer, K, V> getTripleOrNull(K key) {
        if (list == null) {
            return null;
        }
        int hash = key.hashCode();
        return getTripleOrNullWithHash(key, hash);
    }

    private Tuple3<Integer, K, V> getTripleOrNullWithHash(K key, int hash) {
        if (list == null) {
            return null;
        }
        int index = getIndex(hash, list.size());
        List<Tuple3<Integer, K, V>> bucket = list.get(index);
        for (Tuple3<Integer, K, V> triple : bucket) {
            if (triple.get1().equals(hash) && triple.get2().equals(key)) {
                return triple;
            }
        }
        return null;
    }

    /**
     * If the key is present in this map, the behavior is identical to get().
     * Otherwise, the given callback is used to create a value, is inserted,
     * and this inserted value is returned.
     */
    public V getOrInsert(K key, Func0<V> f) {
        Tuple3<Integer, K, V> triple = getTripleOrNull(key);
        if (triple != null) {
            return triple.get3();
        } else {
            V value = f.apply();
            put(key, value);
            return value;
        }
    }

    public V getOrNull(K key) {
        if (list == null) {
            return null;
        }
        int hash = key.hashCode();
        int index = getIndex(hash, list.size());
        List<Tuple3<Integer, K, V>> bucket = list.get(index);
        for (Tuple3<Integer, K, V> triple : bucket) {
            if (triple.get1().equals(hash) && triple.get2().equals(key)) {
                return triple.get3();
            }
        }
        return null;
    }

    public boolean containsKey(K key) {
        return getTripleOrNull(key) != null;
    }

    public V get(K key) {
        Tuple3<Integer, K, V> triple = getTripleOrNull(key);
        if (triple == null) {
            throw XError.withMessage("Key " + Repr.of(key) + " not found in this map");
        }
        return triple.get3();
    }

    public V getOrElse(K key, Func0<V> f) {
        Tuple3<Integer, K, V> triple = getTripleOrNull(key);
        return triple == null ? f.apply() : triple.get3();
    }

    public Optional<V> getOptional(K key) {
        Tuple3<Integer, K, V> triple = getTripleOrNull(key);
        return triple == null ? Optional.empty() : Optional.of(triple.get3());
    }

    private Tuple3<Integer, K, V> removeTripleOrNull(K key) {
        if (list == null) {
            return null;
        }
        int hash = key.hashCode();
        int index = getIndex(hash, list.size());
        List<Tuple3<Integer, K, V>> bucket = list.get(index);
        for (int i = 0; i < bucket.size(); i++) {
            Tuple3<Integer, K, V> triple = bucket.get(i);
            if (triple.get1().equals(hash) && triple.get2().equals(key)) {
                siz--;
                return bucket.removeIndex(i);
            }
        }
        return null;
    }

    public boolean removeOrFalse(K key) {
        Tuple3<Integer, K, V> triple = removeTripleOrNull(key);
        if (triple == null) {
            return false;
        } else {
            return true;
        }
    }

    public void remove(K key) {
        if (removeTripleOrNull(key) == null) {
            throw XError.withMessage("Key " + Repr.of(key) + " not found in this map");
        }
    }

    public XIterator<K> keys() {
        if (list == null) {
            return List.<K>of().iter();
        } else {
            return list.iter().flatMap(bucket -> bucket.map(triple -> triple.get2()));
        }
    }

    public XIterator<V> values() {
        if (list == null) {
            return List.<V>of().iter();
        } else {
            return list.iter().flatMap(bucket -> bucket.map(triple -> triple.get3()));
        }
    }

    public XIterator<Pair<K, V>> pairs() {
        if (list == null) {
            return List.<Pair<K, V>>of().iter();
        } else {
            return list.iter().flatMap(bucket -> bucket.map(triple -> Pair.of(triple.get2(), triple.get3())));
        }
    }

    private static int getIndex(int hash, int size) {
        return (hash % size + size) % size;
    }

    @Override
    public int hashCode() {
        throw XError.withMessage("Maps are not hashable");
    }

    @Override
    @SuppressWarnings("unchecked")
    public boolean equals(Object obj) {
        if (!(obj instanceof Map<?, ?>)) {
            return false;
        }
        var map = (Map<K, ?>) obj;
        if (map.siz != siz) {
            return false;
        }
        if (siz == 0) {
            return map.siz == 0;
        }
        var triples = list.iter().flatMap(bucket -> bucket);
        for (var triple : triples) {
            var hash = triple.get1();
            var k = triple.get2();
            var v = triple.get3();
            var otherTriple = map.getTripleOrNullWithHash(k, hash);
            if (!Eq.of(otherTriple.get3(), v)) {
                return false;
            }
        }
        return true;
    }

    @Override
    public String toString() {
        var sb = Str.builder();
        sb.s("Map.of(");
        boolean first = true;
        for (K key : keys()) {
            if (!first) {
                sb.s(", ");
            }
            first = false;
            sb.s("Pair.of(");
            sb.s(Repr.of(key));
            sb.s(", ");
            sb.s(Repr.of(get(key)));
            sb.s(")");
        }
        sb.s(")");
        return sb.toString();
    }
}
