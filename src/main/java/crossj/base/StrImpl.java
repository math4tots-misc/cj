package crossj.base;

import java.nio.charset.StandardCharsets;
import java.util.Iterator;

final class StrImpl {
    private StrImpl() {
    }

    /**
     * See documentation on Str.codeAt for more information
     */
    public static int codeAt(String string, int index) {
        return string.charAt(index);
    }

    public static int charCode(char c) {
        // NOTE: in Java, chars are zero-extended when converting to larger sized
        // integers.
        return (int) c;
    }

    public static Bytes toUTF8(String string) {
        return Bytes.fromByteBuffer(StandardCharsets.UTF_8.encode(string));
    }

    public static String fromUTF8(Bytes bytes) {
        return StandardCharsets.UTF_8.decode(bytes.getUnderlyingByteBuffer()).toString();
    }

    public static XIterator<Integer> toCodePoints(String string) {
        return XIterator.fromIterator(new Iterator<Integer>() {
            int i = 0;

            @Override
            public boolean hasNext() {
                return i < string.length();
            }

            @Override
            public Integer next() {
                var code = string.codePointAt(i);
                i += Character.charCount(code);
                return code;
            }
        });
    }

    public static String fromCodePoints(XIterable<Integer> codePoints) {
        if (codePoints instanceof IntArray) {
            var array = (IntArray) codePoints;
            return fromSliceOfCodePoints(array, 0, array.size());
        } else {
            var tuple = Tuple.fromIterable(codePoints);
            var points = new int[tuple.size()];
            for (int i = 0; i < points.length; i++) {
                points[i] = tuple.get(i);
            }
            return new String(points, 0, points.length);
        }
    }

    public static String fromSliceOfCodePoints(IntArray codePoints, int start, int end) {
        var len = end - start;
        return new String(codePoints.getJavaArray(), start, len);
    }
}
