package crossj.base;

public final class Pair<A1, A2> implements Comparable<Pair<A1, A2>> {
    private final A1 a1;
    private final A2 a2;

    private Pair(A1 a1, A2 a2) {
        this.a1 = a1;
        this.a2 = a2;
    }

    public static <A1, A2> Pair<A1, A2> of(A1 a1, A2 a2) {
        return new Pair<>(a1, a2);
    }

    public A1 get1() {
        return a1;
    }

    public A2 get2() {
        return a2;
    }

    public List<Object> toList() {
        return List.of(a1, a2);
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof Pair<?, ?>)) {
            return false;
        }
        return toList().equals(((Pair<?, ?>) other).toList());
    }

    @Override
    public int hashCode() {
        return toList().hashCode();
    }

    @Override
    public int compareTo(Pair<A1, A2> o) {
        return toList().compareTo(o.toList());
    }

    @Override
    public String toString() {
        return "Pair.of(" + a1 + ", " + a2 + ")";
    }
}
