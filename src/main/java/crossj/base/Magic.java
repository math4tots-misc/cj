package crossj.base;

/**
 * Methods for some limited level of reflection.
 *
 * Aside from `instanceof` checks, all runtime type information functionality
 * should be collected in this class.
 */
public final class Magic {
    private Magic() {}

    public static boolean haveSameClass(Object a, Object b) {
        return a.getClass() == b.getClass();
    }
}
