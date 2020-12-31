package crossj.base;

/**
 * Random number generator.
 *
 * Not cryptographically secure. More or less based on Java's java.util.Random.
 *
 * TODO: allow seeding
 */
public final class Rand {
    private static final Rand DEFAULT = new Rand(RandImpl.getDefault());

    private final RandImpl imp;
    private double nextNextGaussian;
    private boolean haveNextNextGaussian = false;

    private Rand(RandImpl imp) {
        this.imp = imp;
    }

    public static Rand getDefault() {
        return DEFAULT;
    }

    /**
     * Returns a random number in the range [0, 1)
     */
    public double next() {
        return imp.nextDouble();
    }

    /**
     * Returns a random number in the range [a, b)
     */
    public double nextDouble(double a, double b) {
        return a + (b - a) * next();
    }

    /**
     * Returns a random integer in the range [a, b)
     */
    public int nextInt(int a, int b) {
        return (int) nextDouble(a, b);
    }

    /**
     * Returns the next pseudorandom, normally distributed double value with mean 0
     * and standard deviation 1.
     *
     * More or less based on:
     * https://docs.oracle.com/javase/8/docs/api/java/util/Random.html#nextGaussian--
     */
    public double nextGaussian() {
        if (haveNextNextGaussian) {
            haveNextNextGaussian = false;
            return nextNextGaussian;
        } else {
            double v1, v2, s;
            while (true) {
                v1 = 2 * next() - 1;  // between -1 and 1
                v2 = 2 * next() - 1;  // between -1 and 1
                s = v1 * v1 + v2 * v2;
                if (!(s >= 1 || s == 0)) {
                    break;
                }
            }
            double multiplier = M.sqrt(-2 * M.ln(s)/s);
            nextNextGaussian = v2 * multiplier;
            haveNextNextGaussian = true;
            return v1 * multiplier;
        }
    }

    public <T> T inList(List<T> list) {
        return list.get(nextInt(0, list.size()));
    }

    public <T> T inTuple(Tuple<T> tuple) {
        return tuple.get(nextInt(0, tuple.size()));
    }
}
