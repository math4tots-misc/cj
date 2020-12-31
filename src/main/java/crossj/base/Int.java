package crossj.base;

/**
 * Utilities for doing stuff with integers
 *
 * Since `long` is not allowed in crossj, we use `double` when we need `unsigned int`.
 */
public final class Int {
    private Int() {}

    public static final int MAX_VALUE = 2147483647;
    public static final int MIN_VALUE = -2147483648;

    public static int toSigned(double value) {
        return (int) (value < 2147483648.0 ? value : (value - 4294967296.0));
    }

    public static double toUnsigned(int value) {
        return value >= 0 ? (double) value : (value + 4294967296.0);
    }

    public static int toI16(int u16) {
        return u16 < 32768 ? u16 : (u16 - 65536);
    }

    public static int toU16(int i16) {
        return i16 >= 0 ? i16 : (i16 + 65536);
    }

    public static int toI8(int u8) {
        return u8 < 128 ? u8 : (u8 - 256);
    }

    public static int toU8(int i8) {
        return i8 >= 0 ? i8 : (i8 + 256);
    }
}
