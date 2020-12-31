package crossj.base;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;

public final class List<T> implements XIterable<T>, Comparable<List<T>> {
    private final ArrayList<T> list;

    private List(ArrayList<T> list) {
        this.list = list;
    }

    public static <T> List<T> fromIterator(Iterator<T> iterator) {
        ArrayList<T> list = new ArrayList<>();
        iterator.forEachRemaining(list::add);
        return new List<>(list);
    }

    public static <T> List<T> fromIterable(Iterable<T> iterable) {
        return fromIterator(iterable.iterator());
    }

    @SafeVarargs
    public static <T> List<T> of(T... args) {
        return new List<T>(new ArrayList<>(Arrays.asList(args)));
    }

    /**
     * Just a convenience method since often when a <code>List&lt;Double&gt;</code> is required
     * <code>List.of(..)</code> will still return <code>List&lt;Integer&gt;</code>.
     */
    public static List<Double> ofDoubles(double... args) {
        ArrayList<Double> list = new ArrayList<>();
        for (double arg: args) {
            list.add(arg);
        }
        return new List<>(list);
    }

    public static <T> List<T> fromJavaArray(T[] args) {
        return of(args);
    }

    public static <T> List<T> ofSize(int n, Func0<T> f) {
        List<T> ret = List.of();
        for (int i = 0; i < n; i++) {
            ret.add(f.apply());
        }
        return ret;
    }

    public static <T> List<T> reversed(XIterable<T> iterable) {
        List<T> ret = List.fromIterable(iterable);
        Collections.reverse(ret.list);
        return ret;
    }

    public static <T extends Comparable<T>> List<T> sorted(XIterable<T> iterable) {
        List<T> ret = List.fromIterable(iterable);
        Collections.sort(ret.list);
        return ret;
    }

    public static <T> List<T> sortedBy(XIterable<T> iterable, Func2<Integer, T, T> f) {
        List<T> ret = List.fromIterable(iterable);
        ret.sortBy(f);
        return ret;
    }

    public int size() {
        return list.size();
    }

    public T get(int i) {
        return list.get(i);
    }

    public T last() {
        return list.get(list.size() - 1);
    }

    public void setLast(T t) {
        list.set(list.size() - 1, t);
    }

    public void set(int i, T t) {
        list.set(i, t);
    }

    public T pop() {
        return list.remove(list.size() - 1);
    }

    public List<T> slice(int start, int end) {
        return new List<>(new ArrayList<>(list.subList(start, end)));
    }

    public List<T> sliceFrom(int start) {
        return slice(start, size());
    }

    public List<T> sliceUpto(int end) {
        return slice(0, end);
    }

    public void swap(int i, int j) {
        if (i != j) {
            T value = list.get(i);
            list.set(i, list.get(j));
            list.set(j, value);
        }
    }

    public void reverse() {
        Collections.reverse(list);
    }

    /**
     * Sorts the list with the given comparator.
     *
     * If T implements <code>Comaparable&lt;T&gt;</code>, you can also write:
     *
     * <pre>
     * list.sortBy(Default.comparator());
     * </pre>
     * @param f
     */
    public void sortBy(Func2<Integer, T, T> f) {
        Collections.sort(list, (a, b) -> f.apply(a, b));
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof List<?>)) {
            return false;
        }
        List<?> olist = (List<?>) other;
        return list.equals(olist.list);
    }

    /**
     * TODO: Lists should not be hashable, but Tuples still should be.
     */
    @Override
    public int hashCode() {
        return list.hashCode();
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append('[');
        boolean first = true;
        for (T t: list) {
            if (!first) {
                sb.append(", ");
            }
            first = false;
            sb.append(Repr.of(t));
        }
        sb.append(']');
        return sb.toString();
    }

    public List<T> repeat(int n) {
        List<T> ret = List.of();
        for (int i = 0; i < n; i++) {
            ret.addAll(this);
        }
        return ret;
    }

    public <R> List<R> flatMap(Func1<XIterable<R>, T> f) {
        ArrayList<R> ret = new ArrayList<>();
        for (T t: list) {
            for (R r: f.apply(t)) {
                ret.add(r);
            }
        }
        return new List<>(ret);
    }

    public <R> List<R> map(Func1<R, T> f) {
        ArrayList<R> ret = new ArrayList<>();
        for (T t: list) {
            ret.add(f.apply(t));
        }
        return new List<>(ret);
    }

    public List<T> filter(Func1<Boolean, T> f) {
        ArrayList<T> ret = new ArrayList<>();
        for (T t: list) {
            if (f.apply(t)) {
                ret.add(t);
            }
        }
        return new List<>(ret);
    }

    public <R> R fold(R start, Func2<R, R, T> f) {
        for (T t: list) {
            start = f.apply(start, t);
        }
        return start;
    }

    public T reduce(Func2<T, T, T> f) {
        if (list.isEmpty()) {
            throw new RuntimeException("Reduce on an empty list");
        }
        T start = list.get(0);
        for (T t: list.subList(1, list.size())) {
            start = f.apply(start, t);
        }
        return start;
    }

    @Override
    public XIterator<T> iter() {
        return XIterator.fromIterator(list.iterator());
    }

    public boolean contains(T t) {
        return list.contains(t);
    }

    public void add(T t) {
        list.add(t);
    }

    public void addAll(XIterable<T> ts) {
        ts.forEach(list::add);
    }

    public T removeIndex(int i) {
        return list.remove(i);
    }

    public void removeValue(T t) {
        list.remove(t);
    }

    /**
     * Returns the lowest index i such that <code>Objects.equals(this.get(i), t)</code>
     * Returns -1 if no such index exists.
     */
    public int indexOf(T t) {
        return list.indexOf(t);
    }

    /**
     * Returns the highest index i such that <code>Objects.equals(this.get(i), t)</code>
     * Returns -1 if no such index exists.
     */
    public int lastIndexOf(T t) {
        return list.lastIndexOf(t);
    }

    @SuppressWarnings("unchecked")
    @Override
    public int compareTo(List<T> o) {
        int len = Math.min(size(), o.size());
        for (int i = 0; i < len; i++) {
            T a = list.get(i);
            T b = o.list.get(i);
            int cmp = ((Comparable<T>) a).compareTo(b);
            if (cmp != 0) {
                return cmp;
            }
        }
        return Integer.compare(len, o.size());
    }

    public List<T> clone() {
        return new List<>(new ArrayList<>(list));
    }
}
