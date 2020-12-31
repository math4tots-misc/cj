package crossj.base;

public final class Tuple4<A1, A2, A3, A4> implements Comparable<Tuple4<A1, A2, A3, A4>> {
    private final A1 a1;
    private final A2 a2;
    private final A3 a3;
    private final A4 a4;

    private Tuple4(A1 a1, A2 a2, A3 a3, A4 a4) {
        this.a1 = a1;
        this.a2 = a2;
        this.a3 = a3;
        this.a4 = a4;
    }

    public static <A1, A2, A3, A4> Tuple4<A1, A2, A3, A4> of(A1 a1, A2 a2, A3 a3, A4 a4) {
        return new Tuple4<>(a1, a2, a3, a4);
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

    public A4 get4() {
        return a4;
    }

    public List<Object> toList() {
        return List.of(a1, a2, a3, a4);
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof Tuple4<?, ?, ?, ?>)) {
            return false;
        }
        return toList().equals(((Tuple4<?, ?, ?, ?>) other).toList());
    }

    @Override
    public int hashCode() {
        return toList().hashCode();
    }

    @Override
    public int compareTo(Tuple4<A1, A2, A3, A4> o) {
        return toList().compareTo(o.toList());
    }
}
