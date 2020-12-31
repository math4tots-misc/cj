package crossj.base;

/**
 * Utility for doing equality checks
 */
public final class Eq {
    private Eq() {}

    public static <T> boolean of(T a, T b) {
        return a == null ? b == null : a.equals(b);
    }

    @SuppressWarnings("unchecked")
    public static <T> boolean almost(T a, T b) {
        if (isNumeric(a) && isNumeric(b)) {
            return almostForDouble(asDouble(a), asDouble(b));
        } else if (a instanceof AlmostEq<?> && b instanceof AlmostEq<?>) {
            return ((AlmostEq<T>) a).almostEquals(b);
        } else {
            return of(a, b);
        }
    }

    public static boolean almostForDouble(double a, double b) {
        // TODO: do something smarter here
        return M.abs(a - b) < 0.00000000001;
    }

    private static <T> boolean isNumeric(T x) {
        return x instanceof Double || x instanceof Integer;
    }

    private static <T> double asDouble(T x) {
        if (x instanceof Double) {
            return (Double) x;
        } else if (x instanceof Integer) {
            return (Integer) x;
        } else {
            throw XError.withMessage("Expected numeric value but got " + x);
        }
    }
}
