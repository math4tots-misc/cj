package crossj.base;

public final class Time {
    /**
     * Returns unix time (i.e. seconds since January 1, 1970 UTC)
     * as a double.
     * @return
     */
    public static double now() {
        return System.currentTimeMillis() / 1000.0;
    }
}
