package crossj.base;

import java.util.Iterator;

public final class Range {
    /**
     * Iterator from start to end, not including start but not including end.
     * @param start
     * @param end
     * @return
     */
    public static XIterator<Integer> of(int start, int end) {
        return from(start).take(end - start);
    }

    /**
     * Iterator from start to infinity
     */
    public static XIterator<Integer> from(int start) {
        return XIterator.fromIterator(new Iterator<Integer>(){
            int i = start;

            @Override
            public boolean hasNext() {
                return true;
            }

            @Override
            public Integer next() {
                int value = i;
                i++;
                return value;
            }
        });
    }

    /**
     * Iterator from 0 to end, including 0 but not including end
     */
    public static XIterator<Integer> upto(int end) {
        return of(0, end);
    }
}
