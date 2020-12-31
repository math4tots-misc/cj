package crossj.base.io;

import crossj.base.Disposable;

/**
 * Interface for reading character streams of unicode codepoints.
 */
public interface Reader extends Disposable {

    /**
     * Reads a single unicode codepoint.
     *
     * Returns -1 if the end of the stream has been reached.
     *
     * NOTE: Whereas java.io.Reader.read() returns a single UTF-16 code unit,
     * this interface's read() method returns a proper unicode codepoint.
     */
    int read();
}
