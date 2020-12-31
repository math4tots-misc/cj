package crossj.base;

/**
 * Utilities for dealing with characters.
 */
public final class Char {
    private Char() {}

    /**
     * Returns true if the given codePoint is an ASCII digit
     */
    public static boolean isDigit(int ch) {
        return '0' <= ch && ch <= '9';
    }

    /**
     * Returns true if the given codePoint is an ASCII letter
     */
    public static boolean isLetter(int codePoint) {
        return isUpper(codePoint) || isLower(codePoint);
    }

    /**
     * Returns true if the given codePoint is an uppercase ASCII letter
     */
    public static boolean isUpper(int codePoint) {
        return 'A' <= codePoint && codePoint <= 'Z';
    }

    /**
     * Returns true if the given codePoint is a lowercase ASCII letter
     */
    public static boolean isLower(int codePoint) {
        return 'a' <= codePoint && codePoint <= 'z';
    }
}
