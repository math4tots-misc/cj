package crossj.base;

import java.util.Arrays;
import java.util.HashSet;

public class XSet<T> implements XIterable<T> {
    private final HashSet<T> set;

    private XSet(HashSet<T> set) {
        this.set = set;
    }

    @SafeVarargs
    public static <T> XSet<T> of(T... args) {
        return new XSet<>(new HashSet<>(Arrays.asList(args)));
    }

    public int size() {
        return set.size();
    }

    public boolean contains(T key) {
        return set.contains(key);
    }

    public void add(T key) {
        set.add(key);
    }

    public void remove(T key) {
        set.remove(key);
    }

    @Override
    public XIterator<T> iter() {
        return XIterator.fromIterator(set.iterator());
    }
}
