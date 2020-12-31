package crossj.base;

public interface Func4<R, A, B, C, D> {
    public static <R, A, B, C, D> Func4<R, A, B, C, D> of(Func4<R, A, B, C, D> f) {
        return f;
    }

    public R apply(A a, B b, C c, D d);
}
