package crossj.base;

public final class Tuple5<A1, A2, A3, A4, A5> implements Comparable<Tuple5<A1, A2, A3, A4, A5>> {
    private final A1 a1;
    private final A2 a2;
    private final A3 a3;
    private final A4 a4;
    private final A5 a5;

    private Tuple5(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5) {
        this.a1 = a1;
        this.a2 = a2;
        this.a3 = a3;
        this.a4 = a4;
        this.a5 = a5;
    }

    public static <A1, A2, A3, A4, A5> Tuple5<A1, A2, A3, A4, A5> of(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5) {
        return new Tuple5<>(a1, a2, a3, a4, a5);
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

    public A5 get5() {
        return a5;
    }

    public List<Object> toList() {
        return List.of(a1, a2, a3, a4, a5);
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof Tuple5<?, ?, ?, ?, ?>)) {
            return false;
        }
        return toList().equals(((Tuple5<?, ?, ?, ?, ?>) other).toList());
    }

    @Override
    public int hashCode() {
        return toList().hashCode();
    }

    @Override
    public int compareTo(Tuple5<A1, A2, A3, A4, A5> o) {
        return toList().compareTo(o.toList());
    }
}
