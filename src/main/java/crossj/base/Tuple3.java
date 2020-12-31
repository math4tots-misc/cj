package crossj.base;

public final class Tuple3<A1, A2, A3> implements Comparable<Tuple3<A1, A2, A3>> {
    private final A1 a1;
    private final A2 a2;
    private final A3 a3;

    private Tuple3(A1 a1, A2 a2, A3 a3) {
        this.a1 = a1;
        this.a2 = a2;
        this.a3 = a3;
    }

    public static <A1, A2, A3> Tuple3<A1, A2, A3> of(A1 a1, A2 a2, A3 a3) {
        return new Tuple3<>(a1, a2, a3);
    }

    public A1 get1() {
        return a1;
    }

    public A2 get2() {
        return a2;
    }

    public A3 get3() {
        return a3;
    }

    public List<Object> toList() {
        return List.of(a1, a2, a3);
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof Tuple3<?, ?, ?>)) {
            return false;
        }
        return toList().equals(((Tuple3<?, ?, ?>) other).toList());
    }

    @Override
    public int hashCode() {
        return toList().hashCode();
    }

    @Override
    public int compareTo(Tuple3<A1, A2, A3> o) {
        return toList().compareTo(o.toList());
    }
}
