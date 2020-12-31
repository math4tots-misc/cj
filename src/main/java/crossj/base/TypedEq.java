package crossj.base;

/**
 * Helper interface for implementing 'equals'
 * @param <Self> Should pass the Self final class here
 */
public interface TypedEq<Self> {
    boolean isEqualTo(Self other);

    @Override
    boolean equals(Object obj);

    @SuppressWarnings("unchecked")
    default boolean rawEquals(Object obj) {
        if (Magic.haveSameClass(this, obj)) {
            return isEqualTo((Self) obj);
        } else {
            return false;
        }
    }
}
