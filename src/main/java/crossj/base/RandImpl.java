package crossj.base;

import java.util.Random;

/**
 * Random number generator implementation.
 * Not cryptographically secure.
 * See class crossj.base.Rand for usage.
 */
public final class RandImpl {
    private final Random rng;

    private RandImpl(Random rng) {
        this.rng = rng;
    }

    public static RandImpl getDefault() {
        return new RandImpl(new Random());
    }

    /**
     * Returns a uniformly random double value in the range [0, 1).
     */
    public double nextDouble() {
        return rng.nextDouble();
    }
}
