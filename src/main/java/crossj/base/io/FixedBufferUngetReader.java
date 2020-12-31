package crossj.base.io;

import crossj.base.XError;

final class FixedBufferUngetReader implements UngetReader {
    private final Reader reader;
    private final int[] buffer;
    private int i;

    FixedBufferUngetReader(Reader reader, int bufferSize) {
        this.reader = reader;
        this.buffer = new int[bufferSize];
        this.i = 0;
    }

    @Override
    public void unget(int ch) {
        if (i < buffer.length) {
            buffer[i] = ch;
            i++;
        } else {
            throw XError.withMessage("unget buffer overflow");
        }
    }

    @Override
    public int read() {
        if (i > 0) {
            i--;
            return buffer[i];
        } else {
            return reader.read();
        }
    }

    @Override
    public void dispose() {
        reader.dispose();
    }
}
