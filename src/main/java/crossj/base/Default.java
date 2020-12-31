package crossj.base;

public final class Default {
    public static final <T extends Comparable<T>> Func2<Integer, T, T> comparator() {
        return (a, b) -> a.compareTo(b);
    }
}
