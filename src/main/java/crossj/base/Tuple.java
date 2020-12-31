package crossj.base;

/**
 * Immutable List.
 *
 * In the future, implementation of this class could be optimized per-platform
 */
public final class Tuple<T> implements XIterable<T>, Comparable<Tuple<T>>, TypedEq<Tuple<T>> {
    private final List<T> list;

    private Tuple(List<T> list) {
        this.list = list;
    }

    private static <T> Tuple<T> fromList(List<T> list) {
        return new Tuple<>(list);
    }

    @SafeVarargs
    public static <T> Tuple<T> of(T... args) {
        return fromList(List.fromJavaArray(args));
    }

    public static Tuple<Double> ofDoubles(double... args) {
        return fromList(DoubleArray.fromJavaDoubleArray(args).iter().list());
    }

    public static <T> Tuple<T> fromJavaArray(T[] args) {
        return fromList(List.fromJavaArray(args));
    }

    public static <T> Tuple<T> ofSize(int n, Func0<T> f) {
        return fromList(List.ofSize(n, f));
    }

    public static <T> Tuple<T> fromIterable(XIterable<T> iterable) {
        if (iterable instanceof Tuple<?>) {
            return ((Tuple<T>) iterable);
        } else {
            return fromList(List.fromIterable(iterable));
        }
    }

    public static <T> Tuple<T> reversed(XIterable<T> iterable) {
        return fromList(List.reversed(iterable));
    }

    public static <T extends Comparable<T>> Tuple<T> sorted(XIterable<T> iterable) {
        return fromList(List.sorted(iterable));
    }

    public static <T> Tuple<T> sortedBy(XIterable<T> iterable, Func2<Integer, T, T> f) {
        return fromList(List.sortedBy(iterable, f));
    }

    public int size() {
        return list.size();
    }

    public T get(int i) {
        return list.get(i);
    }

    public T last() {
        return list.last();
    }

    public Tuple<T> slice(int start, int end) {
        return fromList(list.slice(start, end));
    }

    public Tuple<T> sliceFrom(int start) {
        return fromList(list.sliceFrom(start));
    }

    public Tuple<T> sliceUpto(int end) {
        return fromList(list.sliceUpto(end));
    }

    @Override
    public boolean isEqualTo(Tuple<T> other) {
        return list.equals(other.list);
    }

    @Override
    public boolean equals(Object obj) {
        return rawEquals(obj);
    }

    @Override
    public String toString() {
        return "Tuple.of(" + Str.join(", ", list.iter().map(x -> Repr.of(x))) + ")";
    }

    public <R> Tuple<R> flatMap(Func1<XIterable<R>, T> f) {
        return fromList(list.flatMap(t -> f.apply(t)));
    }

    public <R> Tuple<R> map(Func1<R, T> f) {
        return fromList(list.map(f));
    }

    public <R> R fold(R start, Func2<R, R, T> f) {
        return list.fold(start, f);
    }

    public T reduce(Func2<T, T, T> f) {
        return list.reduce(f);
    }

    public Tuple<T> repeat(int n) {
        return fromList(list.repeat(n));
    }

    @Override
    public XIterator<T> iter() {
        return list.iter();
    }

    @Override
    public int compareTo(Tuple<T> o) {
        return list.compareTo(o.list);
    }

    @Override
    public int hashCode() {
        return list.hashCode();
    }
}
