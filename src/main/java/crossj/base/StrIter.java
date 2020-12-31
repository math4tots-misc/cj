package crossj.base;

/**
 * Utility for iterating over a string
 */
public final class StrIter {
    private final String string;
    private int i = 0;

    private StrIter(String string) {
        this.string = string;
    }

    static StrIter of(String string) {
        return new StrIter(string);
    }

    /**
     * Returns a string by slicing from the given start position to the current
     * position.
     */
    public String sliceFrom(int start) {
        return string.substring(start, i);
    }

    /**
     * Returns the codePoint at the current position in the string. You should call
     * the 'hasCodePoint()' method to check that we haven't moved past the end of
     * the string.
     */
    public int peekCodePoint() {
        return string.codePointAt(i);
    }

    /**
     * Returns the codePoint at the current position, and increments the position.
     * You should call 'hashCodePoint()' to check that we are not yet past the end
     * of the string.
     */
    public int nextCodePoint() {
        var codePoint = peekCodePoint();
        incr();
        return codePoint;
    }

    /**
     * Increments this iterator to the next codepoint in the string.
     */
    public void incr() {
        if (Character.isSurrogate(string.charAt(i))) {
            i += 2;
        } else {
            i++;
        }
    }

    /**
     * Decrements this iterator to the previous codepoint in the string.
     */
    public void decr() {
        if (i > 1 && Character.isSurrogate(string.charAt(i - 1))) {
            i -= 2;
        } else {
            i--;
        }
    }

    /**
     * Increment this iterator n times
     */
    public void incrN(int n) {
        while (n > 0) {
            incr();
            n--;
        }
    }

    /**
     * Decrement this iterator n times
     */
    public void decrN(int n) {
        while (n > 0) {
            decr();
            n--;
        }
    }

    /**
     * Returns true if there are still more characters to process and getCodePoint()
     * will return a valid value. Otherwise, we have seeked past the end of the
     * given string.
     */
    public boolean hasCodePoint() {
        return i < string.length();
    }

    /**
     * Checks if the substring starting form the current position to the end starts
     * with the given prefix.
     */
    public boolean startsWith(String prefix) {
        return string.startsWith(prefix, i);
    }

    /**
     * Rewinds the iterator to the beginning of the string
     */
    public void seekToStart() {
        i = 0;
    }

    /**
     * Moves the iterator to the end of the string
     */
    public void seekToEnd() {
        i = string.length();
    }

    /**
     * Returns an integer that represents the current position in the string.
     */
    public int getPosition() {
        return i;
    }

    /**
     * Sets the current position in the string.
     *
     * Only return values from getPosition() of the same instance of StrIter should
     * be passed to this method.
     */
    public void setPosition(int i) {
        this.i = i;
    }

    /**
     * Checks if the substring starting from the beginning of the string to the
     * current position ends with the given suffix.
     */
    public boolean endsWith(String suffix) {
        int len = suffix.length();
        return string.regionMatches(i - len, suffix, 0, len);
    }

    public String getString() {
        return string;
    }
}
