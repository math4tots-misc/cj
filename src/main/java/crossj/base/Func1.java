package crossj.base;

public interface Func1<R, A> {
    public static <R, A> Func1<R, A> of(Func1<R, A> f) {
        return f;
    }

    public R apply(A a);
}
