package crossj.base;

public final class Set<T> implements XIterable<T> {
    private final Map<T, Boolean> map;

    private Set(Map<T, Boolean> map) {
        this.map = map;
    }

    @SafeVarargs
    public static <T> Set<T> of(T... args) {
        Map<T, Boolean> map = Map.of();
        for (T arg: args) {
            map.put(arg, true);
        }
        return new Set<>(map);
    }

    public static <T> Set<T> fromIterable(Iterable<T> args) {
        Set<T> set = Set.of();
        for (T arg: args) {
            set.add(arg);
        }
        return set;
    }

    public int size() {
        return map.size();
    }

    public boolean contains(T key) {
        return map.containsKey(key);
    }

    public void add(T key) {
        map.put(key, true);
    }

    public void addAll(XIterable<T> iterable) {
        for (T t : iterable) {
            add(t);
        }
    }

    public boolean removeOrFalse(T key) {
        return map.removeOrFalse(key);
    }

    public void remove(T key) {
        map.remove(key);
    }

    @Override
    public XIterator<T> iter() {
        return map.keys();
    }

    @Override
    public String toString() {
        var sb = Str.builder();
        sb.s("Set.of(");
        var first = true;
        for (var key : this) {
            if (!first) {
                sb.s(", ");
            }
            first = false;
            sb.s("" + key);
        }
        sb.s(")");
        return sb.toString();
    }

    @Override
    public int hashCode() {
        throw XError.withMessage("Sets are not hashable");
    }

    @Override
    public boolean equals(Object obj) {
        return (obj instanceof Set<?>) && (map.equals(((Set<?>) obj).map));
    }
}
