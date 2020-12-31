package crossj.cj;

import crossj.base.Repr;

public final class CJMark implements Repr {
    public final String filename;
    public final int line;
    public final int column;

    private CJMark(String filename, int line, int column) {
        this.filename = filename;
        this.line = line;
        this.column = column;
    }

    public static CJMark of(String filename, int line, int column) {
        return new CJMark(filename, line, column);
    }

    public static CJMark fromToken(String filename, CJToken token) {
        return of(filename, token.line, token.column);
    }

    @Override
    public String repr() {
        return "CJMark.of(" + Repr.reprstr(filename) + ", " + line + ", " + column + ")";
    }

    @Override
    public String toString() {
        return "in " + filename + " on " + line + ":" + column;
    }
}
