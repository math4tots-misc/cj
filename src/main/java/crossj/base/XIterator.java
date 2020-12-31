package crossj.base;

import java.util.Iterator;

/**
 * For Java, XIterator<T> is just a wrapped Iterator with many
 * convenience methods
 *
 * Many of the methods here effectiely 'consume' 'this' XIterator.
 * Continuing to use an XIterator after it has been consumed may
 * cause strange behavior.
 *
 */
public final class XIterator<T> implements Iterator<T>, XIterable<T> {
    private final Iterator<T> iter;

    private XIterator(Iterator<T> iter) {
        this.iter = iter;
    }

    public static <T> XIterator<T> fromIterator(Iterator<T> iter) {
        return new XIterator<>(iter);
    }

    public static <T> XIterator<T> fromParts(Func0<Boolean> hasNext, Func0<T> getNext) {
        return fromIterator(new Iterator<T>(){
            @Override
            public boolean hasNext() {
                return hasNext.apply();
            }

            @Override
            public T next() {
                return getNext.apply();
            }
        });
    }

    @Override
    public boolean hasNext() {
        return iter.hasNext();
    }

    @Override
    public T next() {
        return iter.next();
    }

    @Override
    public XIterator<T> iter() {
        return this;
    }

    @Override
    public Iterator<T> iterator() {
        return iter;
    }

    public List<T> list() {
        return List.fromIterator(this);
    }

    public XIterator<List<T>> chunk(int n) {
        return new XIterator<>(new Iterator<List<T>>(){
            @Override
            public boolean hasNext() {
                return iter.hasNext();
            }

            @Override
            public List<T> next() {
                if (!hasNext()) {
                    throw XError.withMessage("chunk.next called when hasNext is false");
                }
                List<T> ret = List.of(iter.next());
                while (ret.size() < n && iter.hasNext()) {
                    ret.add(iter.next());
                }
                return ret;
            }
        });
    }

    public XIterator<T> take(int n) {
        return new XIterator<>(new Iterator<T>() {
            int i = 0;

            @Override
            public boolean hasNext() {
                return i < n && iter.hasNext();
            }

            @Override
            public T next() {
                i++;
                return iter.next();
            }
        });
    }

    public XIterator<T> skip(int n) {
        for (int i = 0; i < n && hasNext(); i++) {
            next();
        }
        return this;
    }

    public List<T> pop(int n) {
        var list = List.<T>of();
        for (int i = 0; i < n && hasNext(); i++) {
            list.add(next());
        }
        return list;
    }

    public <R> XIterator<R> flatMap(Func1<XIterable<R>, T> f) {
        return new XIterator<>(new Iterator<R>() {
            boolean done = false;
            Iterator<R> current = null;

            @Override
            public boolean hasNext() {
                if (done) {
                    return false;
                }
                while (true) {
                    if (current == null || !current.hasNext()) {
                        if (!iter.hasNext()) {
                            done = true;
                            return false;
                        }
                        current = f.apply(iter.next()).iterator();
                    }
                    if (current.hasNext()) {
                        return true;
                    }
                }
            }

            @Override
            public R next() {
                if (hasNext()) {
                    return current.next();
                } else {
                    throw XError.withMessage("next on empty iterator");
                }
            }
        });
    }

    public <R> XIterator<R> map(Func1<R, T> f) {
        return new XIterator<>(new Iterator<R>(){
            @Override
            public boolean hasNext() {
                return iter.hasNext();
            }

            @Override
            public R next() {
                return f.apply(iter.next());
            }
        });
    }

    public XIterator<T> filter(Func1<Boolean, T> f) {
        return new XIterator<>(new Iterator<T>() {
            T peek = null;
            boolean done = false;

            public T peek() {
                if (done) {
                    return null;
                } else if (peek != null) {
                    return peek;
                } else {
                    while (iter.hasNext()) {
                        if (f.apply((peek = iter.next()))) {
                            break;
                        } else {
                            peek = null;
                        }
                    }
                    return peek;
                }
            }

            @Override
            public boolean hasNext() {
                return peek() != null;
            }

            @Override
            public T next() {
                T value = peek();
                peek = null;
                return value;
            }
        });
    }

    public <R> R fold(R start, Func2<R, R, T> f) {
        while (iter.hasNext()) {
            T t = iter.next();
            start = f.apply(start, t);
        }
        return start;
    }

    public T reduce(Func2<T, T, T> f) {
        if (!iter.hasNext()) {
            throw new RuntimeException("reduce on empty XIterator");
        }
        T start = iter.next();
        return fold(start, f);
    }

    public boolean any(Func1<Boolean, T> f) {
        for (T t: this) {
            if (f.apply(t)) {
                return true;
            }
        }
        return false;
    }

    public boolean all(Func1<Boolean, T> f) {
        for (T t: this) {
            if (!f.apply(t)) {
                return false;
            }
        }
        return true;
    }
}
