package crossj.base;

public interface Func3<R, A, B, C> {
    public static <R, A, B, C> Func3<R, A, B, C> of(Func3<R, A, B, C> f) {
        return f;
    }

    public R apply(A a, B b, C c);
}
