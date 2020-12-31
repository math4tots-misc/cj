package crossj.base;

import java.util.HashMap;

public final class XMap<K, V> {
    private final HashMap<K, V> map;

    private XMap(HashMap<K, V> map) {
        this.map = map;
    }

    @SafeVarargs
    public static <K, V> XMap<K, V> of(Pair<K, V>... pairs) {
        HashMap<K, V> map = new HashMap<>();
        for (Pair<K, V> pair: pairs) {
            map.put(pair.get1(), pair.get2());
        }
        return new XMap<>(map);
    }

    public int size() {
        return map.size();
    }

    public V get(K key) {
        return map.get(key);
    }

    public void put(K key, V value) {
        map.put(key, value);
    }

    public boolean containsKey(K key) {
        return map.containsKey(key);
    }

    public XIterator<K> keys() {
        return XIterator.fromIterator(map.keySet().iterator());
    }

    public XIterator<V> values() {
        return XIterator.fromIterator(map.values().iterator());
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        for (K key: keys()) {
            sb.append(Repr.of(key));
            sb.append(": ");
            sb.append(Repr.of(get(key)));
            sb.append(", ");
        }
        sb.append("}");
        return sb.toString();
    }
}
