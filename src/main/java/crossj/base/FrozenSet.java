package crossj.base;

public final class FrozenSet<T> implements XIterable<T> {
    private final Set<T> set;
    private int hash = 0;

    private FrozenSet(Set<T> set) {
        this.set = set;
    }

    @SafeVarargs
    public static <T> FrozenSet<T> of(T... args) {
        return fromIterable(List.fromJavaArray(args));
    }

    public static <T> FrozenSet<T> fromIterable(XIterable<T> iterable) {
        if (iterable instanceof FrozenSet<?>) {
            return (FrozenSet<T>) iterable;
        } else {
            return new FrozenSet<>(Set.fromIterable(iterable));
        }
    }

    @SafeVarargs
    public static <T> FrozenSet<T> join(XIterable<T>... iterable) {
        return fromIterable(List.fromJavaArray(iterable).iter().flatMap(i -> i));
    }

    @Override
    public XIterator<T> iter() {
        return set.iter();
    }

    public int size() {
        return set.size();
    }

    public boolean contains(T key) {
        return set.contains(key);
    }

    @Override
    public String toString() {
        var sb = Str.builder();
        sb.s("FrozenSet.of(");
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
    public boolean equals(Object obj) {
        return (obj instanceof FrozenSet<?>) && set.equals(((FrozenSet<?>) obj).set);
    }

    @Override
    public int hashCode() {
        if (hash == 0) {
            hash = 1 + set.iter().map(obj -> obj.hashCode()).fold(0, (a, b) -> a + b);
        }
        return hash;
    }
}
