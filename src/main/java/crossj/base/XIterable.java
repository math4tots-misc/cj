package crossj.base;

import java.util.Iterator;

public interface XIterable<T> extends Iterable<T> {
    public XIterator<T> iter();

    @Override
    default Iterator<T> iterator() {
        return iter().iterator();
    }
}
