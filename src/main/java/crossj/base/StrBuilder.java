package crossj.base;

/**
 * Wrapper around StringBuilder
 */
public final class StrBuilder {
    private final StringBuilder builder = new StringBuilder();

    StrBuilder() {
    }

    public String build() {
        return builder.toString();
    }

    /**
     * Append the string representation of an arbitrary object
     *
     * NOTE: if a Character object is passed, it may be treated as though
     * an int of the equivalent value was passed. This is because on some platforms
     * it is not always possible to distinguish between Characters and Integers at
     * runtime.
     */
    public StrBuilder obj(Object object) {
        builder.append(object);
        return this;
    }

    /**
     * Append a String representation of a char (as though this.s(Str.fromChar(c)) was called)
     *
     * NOTE: the behavior of this method may be different from passing a char
     * to the 'append()' method, because on some targets (e.g. JS), a char that is cast
     * to an Object may be indistinguishable from an integer.
     */
    public StrBuilder c(char c) {
        builder.append(c);
        return this;
    }

    /**
     * Append a unicode codepoint
     */
    public StrBuilder codePoint(int codePoint) {
        builder.appendCodePoint(codePoint);
        return this;
    }

    /**
     * Append the string representation of an integer
     */
    public StrBuilder i(int i) {
        builder.append(i);
        return this;
    }

    /**
     * Append the string representation of a double
     */
    public StrBuilder d(double d) {
        builder.append(d);
        return this;
    }

    /**
     * Append a string
     */
    public StrBuilder s(String s) {
        builder.append(s);
        return this;
    }

    public StrBuilder repeatStr(String string, int count) {
        for (int i = 0; i < count; i++) {
            s(string);
        }
        return this;
    }

    @Override
    public String toString() {
        return build();
    }
}
