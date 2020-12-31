package crossj.base.io;

import crossj.base.Str;
import crossj.base.StrIter;

public final class StringReader implements Reader {
    private final StrIter iter;

    private StringReader(StrIter iter) {
        this.iter = iter;
    }

    public static StringReader of(String string) {
        return new StringReader(Str.iter(string));
    }

    @Override
    public int read() {
        if (iter.hasCodePoint()) {
            return iter.nextCodePoint();
        } else {
            return -1;
        }
    }

    @Override
    public void dispose() {
    }
}
