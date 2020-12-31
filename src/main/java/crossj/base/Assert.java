package crossj.base;

public final class Assert {
    private Assert() {
    }

    public static void that(boolean cond) {
        if (!cond) {
            throw XError.withMessage("Assertion failed");
        }
    }

    public static void unreachable() {
        throw XError.withMessage("Unreachable assertion failed");
    }

    public static void withMessage(boolean cond, String message) {
        if (!cond) {
            throw XError.withMessage("Assertion failed: " + message);
        }
    }

    public static <T> void equals(T a, T b) {
        if (!Eq.of(a, b)) {
            throw XError.withMessage("Assertion failed, expected " + Repr.of(a) + " to equal " + Repr.of(b));
        }
    }

    public static <T> void equalsWithMessage(T a, T b, String message) {
        if (!Eq.of(a, b)) {
            throw XError.withMessage(
                    "Assertion failed, expected " + Repr.of(a) + " to equal " + Repr.of(b) + " (" + message + ")");
        }
    }

    public static <T> void notEquals(T a, T b) {
        if (Eq.of(a, b)) {
            throw XError.withMessage("Assertion failed, expected " + Repr.of(a) + " to NOT equal " + Repr.of(b));
        }
    }

    public static <T> void almostEquals(T a, T b) {
        if (!Eq.almost(a, b)) {
            throw XError
                    .withMessage("Assertion failed, expected " + Repr.of(a) + " to be almost equal to " + Repr.of(b));
        }
    }

    public static <T> void notAlmostEquals(T a, T b) {
        if (Eq.almost(a, b)) {
            throw XError.withMessage(
                    "Assertion failed, expected " + Repr.of(a) + " to NOT be almost equal to " + Repr.of(b));
        }
    }

    public static <A extends Comparable<B>, B> void less(A a, B b) {
        if (a.compareTo(b) >= 0) {
            throw XError.withMessage("Assertion failed, expected " + Repr.of(a) + " to be less than " + Repr.of(b));
        }
    }

    public static <A extends Comparable<B>, B> void lessThanOrEqual(A a, B b) {
        if (a.compareTo(b) > 0) {
            throw XError.withMessage(
                    "Assertion failed, expected " + Repr.of(a) + " to be less than or equal to " + Repr.of(b));
        }
    }

    public static <A extends Comparable<B>, B> void notLess(A a, B b) {
        if (a.compareTo(b) < 0) {
            throw XError.withMessage("Assertion failed, expected " + Repr.of(a) + " to be NOT less than " + Repr.of(b));
        }
    }

    public static <A extends Comparable<B>, B extends Comparable<C>, C> void order(A a, B b, C c) {
        if (!(a.compareTo(b) <= 0 && b.compareTo(c) <= 0)) {
            throw XError.withMessage(
                    "Assertion failed, expected " + Repr.of(a) + " <= " + Repr.of(b) + " <= " + Repr.of(c));
        }
    }

    public static void divides(int divisor, int dividend) {
        if (dividend % divisor != 0) {
            throw XError
                    .withMessage("Assertion failed, expected " + Repr.of(divisor) + " to divide " + Repr.of(dividend));
        }
    }

    public static void raise(Func0<Void> f) {
        boolean thrown = false;
        try {
            f.apply();
        } catch (XError e) {
            thrown = true;
        }
        if (!thrown) {
            throw XError.withMessage("Assertion failed, expected exception not raised");
        }
    }
}
