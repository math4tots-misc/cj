package com.github.math4tots.java2cj;

/**
 * Formatted String Builder
 */
public final class FSB {
    private final StringBuilder sb = new StringBuilder();
    private int depth = 0;

    private void emitIndent() {
        sb.append(" ".repeat(4 * depth));
    }

    public void indent() {
        depth++;
    }

    public void dedent() {
        depth--;
    }

    public void line(String line) {
        emitIndent();
        sb.append(line);
        sb.append('\n');
    }

    @Override
    public String toString() {
        return sb.toString();
    }
}
