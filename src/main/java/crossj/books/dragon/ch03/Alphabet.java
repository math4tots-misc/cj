package crossj.books.dragon.ch03;

/**
 * The set of alphabets that dragon.ch03 works on.
 *
 * To keep things simple, our alphabet range is ASCII, and any value outside
 * that range is mapped to Alphabet.CATCH_ALL (127).
 */
public final class Alphabet {
    private Alphabet() {
    }

    /**
     * The number of letters in this alphabet.
     */
    public static final int COUNT = 128;

    /**
     * The catch-all value that non-ASCII values will be mapped to.
     */
    public static final int CATCH_ALL = 127;

    public static boolean contains(int letter) {
        return 0 <= letter && letter < COUNT;
    }
}
