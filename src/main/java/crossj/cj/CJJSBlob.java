package crossj.cj;

import crossj.base.List;

/**
 * A blob of translated Javascript statements and expression.
 */
public final class CJJSBlob {
    private final List<String> lines;
    private final String expression;
    private final boolean pure;

    CJJSBlob(List<String> lines, String expression, boolean pure) {
        this.lines = lines;
        this.expression = expression;
        this.pure = pure;
    }

    static CJJSBlob inline(String expression, boolean pure) {
        return new CJJSBlob(List.of(), expression, pure);
    }

    public List<String> getLines() {
        return lines;
    }

    public String getExpression() {
        return expression;
    }

    /**
     * Indicates whether the blob's associated expression has any side effects.
     */
    public boolean isPure() {
        return pure;
    }

    /**
     * Indicates that there are no extra statements need to be prepended.
     */
    public boolean isSimple() {
        return lines.size() == 0;
    }

    public boolean isSimpleAndPure() {
        return isSimple() && isPure();
    }

    /**
     * Returns a version of CJJSBlob that is pure. If 'this' is already pure,
     * returns 'this', otherwise stores the result in a tempvar.
     */
    public CJJSBlob toPure(CJJSContext ctx) {
        if (pure) {
            return this;
        } else {
            var newLines = List.fromIterable(lines);
            var v = ctx.newTempVarName();
            newLines.add("const " + v + "=" + expression + ";\n");
            return new CJJSBlob(newLines, v, true);
        }
    }

    /**
     * Adds a list of lines that executes all the side effects of this blob.
     *
     * In particular, if this is pure, adds just the lines, otherwise, it adds
     * the lines appended with an extra line that evaluates and drops the expression.
     */
    public void dropValue(List<String> outLines) {
        outLines.addAll(lines);
        if (!pure) {
            outLines.add(expression + ";\n");
        }
    }

    /**
     * Adds a list of lines that executes all the side effects of this blob,
     * then adds a last statement with the expression preceded by the given prefix.
     */
    public void setValue(List<String> outLines, String prefix) {
        outLines.addAll(lines);
        outLines.add(prefix + expression + ";\n");
    }

    @Override
    public String toString() {
        throw new RuntimeException();
    }
}
