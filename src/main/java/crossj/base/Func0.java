package crossj.base;

public interface Func0<R> {
    public static <R> Func0<R> of(Func0<R> f) {
        return f;
    }

    public R apply();
}
