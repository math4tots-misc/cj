package crossj.base;

// The name 'Self' is a hint that the type parameter here really should
// always be the actual class type
public interface AlmostEq<Self> {
    public boolean almostEquals(Self other);
}
