package crossj.base;

/**
 * Double ended queue
 */
public final class Deque<T> implements XIterable<T> {

    public static <T> Deque<T> fromIterable(XIterable<T> iterable) {
        return new Deque<>(List.fromIterable(iterable), 0);
    }

    @SafeVarargs
    public static <T> Deque<T> of(T... args) {
        return new Deque<>(List.fromJavaArray(args), 0);
    }

    public static Deque<Double> ofDoubles(double... args) {
        var list = List.<Double>of();
        for (double arg : args) {
            list.add(arg);
        }
        return new Deque<>(list, 0);
    }

    private List<T> buffer;
    private int start;

    private Deque(List<T> buffer, int start) {
        this.buffer = buffer;
        this.start = start;
    }

    @Override
    public XIterator<T> iter() {
        var helper = new DequeIteratorHelper<>(start);
        return XIterator.fromParts(() -> helper.i < buffer.size(), () -> {
            var t = buffer.get(helper.i);
            helper.i += 1;
            return t;
        });
    }

    private void reserveLeftSpace(int newStart) {
        if (newStart > start) {
            int len = size();
            var newBuffer = List.<T>ofSize(newStart + len, () -> null);
            for (int i = 0; i < len; i++) {
                newBuffer.set(i + newStart, buffer.get(start + i));
            }
            buffer = newBuffer;
            start = newStart;
        }
    }

    public int size() {
        return buffer.size() - start;
    }

    public T last() {
        Assert.that(size() > 0);
        return buffer.last();
    }

    public T get(int i) {
        Assert.that(i > 0);
        return buffer.get(start + i);
    }

    public void set(int i, T t) {
        Assert.that(i > 0);
        buffer.set(start + i, t);
    }

    public void swap(int i, int j) {
        if (i != j) {
            buffer.swap(start + i, start + j);
        }
    }

    public void add(T t) {
        buffer.add(t);
    }

    public void addAll(XIterable<T> iterable) {
        buffer.addAll(iterable);
    }

    public T pop() {
        Assert.that(size() > 0);
        return buffer.pop();
    }

    public void addLeft(T t) {
        if (start <= 0) {
            reserveLeftSpace(M.imax(4, size()));
        }
        start--;
        buffer.set(start, t);
    }

    public T popLeft() {
        Assert.that(size() > 0);
        T ret = buffer.get(start);
        buffer.set(start, null);
        start++;
        return ret;
    }
}
