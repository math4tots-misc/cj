package crossj.base;

public final class Compare {
    private Compare() {}

    public static int ints(int a, int b) {
        return a == b ? 0 : a < b ? -1 : 1;
    }

    public static int doubles(double a, double b) {
        return a == b ? 0 : a < b ? -1 : 1;
    }

    public static <A extends Comparable<B>, B> int optionals(Optional<A> a, Optional<B> b) {
        if (a.isEmpty()) {
            if (b.isEmpty()) {
                return 0;
            } else {
                return -1;
            }
        } else if (b.isEmpty()) {
            return 1;
        } else {
            return a.get().compareTo(b.get());
        }
    }

    public static <A extends Comparable<B>, B> int objects(A a, B b) {
        return a.compareTo(b);
    }
}
