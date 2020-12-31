package crossj.base;

public interface Func2<R, A, B> {
    public static <R, A, B> Func2<R, A, B> of(Func2<R, A, B> f) {
        return f;
    }

    public R apply(A a, B b);
}
