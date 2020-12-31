package crossj.base.io;

/**
 * A Reader that has the ability to 'unget' characters into a stack for rereading them in the future.
 */
public interface UngetReader extends Reader {

    static UngetReader withFixedBuffer(int bufferSize, Reader reader) {
        return new FixedBufferUngetReader(reader, bufferSize);
    }

    void unget(int ch);
}
