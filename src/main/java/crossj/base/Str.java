package crossj.base;

/**
 * Some basic utils for manipulating strings.
 */
public final class Str {
    private Str() {
    }

    public static String of(Object value) {
        return value.toString();
    }

    /**
     * Returns a UTF code unit.
     *
     * The actual value returned depends on the platform.
     *
     * There are three possible cases:
     *
     * <li>1: <b>UTF-16</b> Targets: Java, JavaScript, C#. In this scenario, all
     * strings are assumed to be represented internally as UTF-16. The method will
     * return a value between 0 and 65535 representing the UTF-16 code unit.</li>
     * <li>2: <b>UTF-8</b> Targets: C/C++, Rust. In this scenario, all strings are
     * assumed to be represented internally as UTF-8. The method will return a value
     * between 0 and 255 representing a UTF-8 code unit.</li>
     * <li>3: <b>UCS-4/UTF-32</b> Targets: Python. Every unicode character can be
     * indexed directly. The method will return a full unicode codepoint.</li>
     *
     */
    public static int codeAt(String string, int index) {
        return StrImpl.codeAt(string, index);
    }

    public static int code(char c) {
        return StrImpl.charCode(c);
    }

    public static StrBuilder builder() {
        return new StrBuilder();
    }

    public static StrIter iter(String string) {
        return StrIter.of(string);
    }

    public static String unescape(String escaped) {
        final int DEFAULT = 0;
        final int ESCAPE = 1;
        final int HEX_SEQ_1 = 2;
        final int HEX_SEQ_2 = 3;
        var sb = Str.builder();
        int state = 0;
        int byteSeqPart = 0;
        for (var ch : toCodePoints(escaped)) {
            switch (state) {
                // default
                case DEFAULT: {
                    if (ch == (int) '\\') {
                        state = ESCAPE;
                    } else {
                        sb.codePoint(ch);
                    }
                    break;
                }
                // escape sequence
                case ESCAPE: {
                    switch (ch) {
                        case (int) '\0':
                            sb.codePoint('\0');
                            state = DEFAULT;
                            break;
                        case (int) '\\':
                            sb.codePoint('\\');
                            state = DEFAULT;
                            break;
                        case (int) 'r':
                            sb.codePoint('\r');
                            state = DEFAULT;
                            break;
                        case (int) 'n':
                            sb.codePoint('\n');
                            state = DEFAULT;
                            break;
                        case (int) 't':
                            sb.codePoint('\t');
                            state = DEFAULT;
                            break;
                        case (int) '"':
                            sb.codePoint('\"');
                            state = DEFAULT;
                            break;
                        case (int) '\'':
                            sb.codePoint('\'');
                            state = DEFAULT;
                            break;
                        case (int) 'x':
                            state = HEX_SEQ_1;
                            break;
                        default:
                            throw XError.withMessage("Unrecognized escape character " + ch);
                    }
                    break;
                }
                case HEX_SEQ_1:
                    byteSeqPart = ch;
                    state = HEX_SEQ_2;
                    break;
                case HEX_SEQ_2: {
                    sb.codePoint(hexCodeFromDigits(byteSeqPart, ch));
                    state = DEFAULT;
                    break;
                }
                default:
                    throw XError.withMessage("Invalid state: " + state);
            }
        }
        if (state != DEFAULT) {
            throw XError.withMessage("Incomplete escape (" + escaped + ")");
        }
        return sb.build();
    }

    private static int hexDigitToValue(int codePoint) {
        if (codePoint >= (int) '0' && codePoint <= (int) '9') {
            return codePoint - (int) '0';
        } else if (codePoint >= (int) 'A' && codePoint <= (int) 'F') {
            return codePoint - (int) 'A';
        } else if (codePoint >= (int) 'a' && codePoint <= (int) 'f') {
            return codePoint - (int) 'a';
        } else {
            throw XError.withMessage("Invalid digit: " + fromCodePoint(codePoint));
        }
    }

    private static int hexCodeFromDigits(int firstChar, int secondChar) {
        return hexDigitToValue(firstChar) * 16 + secondChar;
    }

    public static String join(String separator, XIterable<?> iterable) {
        var sb = Str.builder();
        boolean first = true;
        for (Object obj : iterable) {
            if (!first) {
                sb.s(separator);
            }
            first = false;
            sb.obj(obj);
        }
        return sb.build();
    }

    public static List<String> split(String string, String separator) {
        List<String> parts = List.of();
        int len = string.length();
        int nextStart = 0, i = 0;
        while (i < len) {
            if (startsWithAt(string, separator, i)) {
                parts.add(string.substring(nextStart, i));
                i += separator.length();
                nextStart = i;
            } else {
                i++;
            }
        }
        parts.add(string.substring(nextStart, len));
        return parts;
    }

    public static String upto(String string, int i) {
        return string.substring(0, i);
    }

    public static String from(String string, int i) {
        return string.substring(i, string.length());
    }

    public static boolean isSpaceChar(char ch) {
        return ImplChar.isWhitespace(ch);
    }

    public static String strip(String string) {
        int len = string.length();
        int start = 0;
        while (start < len && isSpaceChar(string.charAt(start))) {
            start++;
        }
        int end = len;
        while (len > 0 && isSpaceChar(string.charAt(end - 1))) {
            end--;
        }
        return string.substring(start, end);
    }

    public static List<String> lines(String string) {
        return split(string, "\n");
    }

    public static List<String> words(String string) {
        List<String> parts = List.of();
        int len = string.length();
        int nextStart = 0, i = 0;
        while (i < len) {
            if (isSpaceChar(string.charAt(i))) {
                if (i > nextStart) {
                    parts.add(string.substring(nextStart, i));
                }
                while (i < len && isSpaceChar(string.charAt(i))) {
                    i++;
                }
                nextStart = i;
            } else {
                i++;
            }
        }
        if (len > nextStart) {
            parts.add(string.substring(nextStart, len));
        }
        return parts;
    }

    /**
     * Converts a string into a Bytes object containing its UTF8 representation.
     */
    public static Bytes toUTF8(String string) {
        return StrImpl.toUTF8(string);
    }

    /**
     * Converts UTF8 bytes into a String object.
     *
     * The behavior is undefined if bytes is not valid UTF8.
     *
     * (It may throw an exception, or invalid values may be replaced with
     * placeholders)
     */
    public static String fromUTF8(Bytes bytes) {
        return StrImpl.fromUTF8(bytes);
    }

    /**
     * Iterate over the codepoints of a string.
     */
    public static XIterator<Integer> toCodePoints(String string) {
        return StrImpl.toCodePoints(string);
    }

    /**
     * Get a string from some codepoints.
     */
    public static String fromCodePoints(XIterable<Integer> codePoints) {
        return StrImpl.fromCodePoints(codePoints);
    }

    public static String fromCodePoint(int codePoint) {
        return StrImpl.fromCodePoints(IntArray.of(codePoint));
    }

    public static IntArray toUTF32(String string) {
        return IntArray.fromIterable(toCodePoints(string));
    }

    public static String fromUTF32(IntArray codePoints) {
        return fromSliceOfCodePoints(codePoints, 0, codePoints.size());
    }

    public static String fromSliceOfCodePoints(IntArray codePoints, int start, int end) {
        return StrImpl.fromSliceOfCodePoints(codePoints, start, end);
    }

    public static boolean startsWithAt(String string, String prefix, int start) {
        return equalsSubstring(string, prefix, start, start + prefix.length());
    }

    public static boolean startsWith(String string, String prefix) {
        return startsWithAt(string, prefix, 0);
    }

    public static boolean endsWithAt(String string, String suffix, int end) {
        return equalsSubstring(string, suffix, end - suffix.length(), end);
    }

    public static boolean endsWith(String string, String suffix) {
        return endsWithAt(string, suffix, string.length());
    }

    public static boolean equalsSubstring(String string, String part, int start, int end) {
        if (start < 0) {
            start = 0;
        }
        if (end > string.length()) {
            end = string.length();
        }
        if (part.length() != end - start) {
            return false;
        }
        return string.substring(start, end).equals(part);
    }

    /**
     * Pad a string to a given length by repeatedly adding a given prefix to the
     * left. If the prefix has length greater than 1, the final string might exceed
     * the given limit even if originally it had length less than 'len'.
     */
    public static String lpad(String string, int len, String prefix) {
        while (string.length() < len) {
            string = prefix + string;
        }
        return string;
    }

    /**
     * Pad a string to a given length by repeatedly adding a given suffix to the
     * right. If the suffix has length greater than 1, the final string might exceed
     * the given limit even if originally it had length less than 'len'.
     */
    public static String rpad(String string, int len, String suffix) {
        while (string.length() < len) {
            string += suffix;
        }
        return string;
    }

    public static String fromIntWithBase(int value, int base) {
        Assert.lessThanOrEqual(base, 10 + 26);
        var sb = builder();
        if (value == 0) {
            sb.c('0');
        } else {
            var digits = List.<Integer>of();
            for (; value > 0; value /= base) {
                int digitValue = value % base;
                int digit = digitValue < 10 ? '0' + digitValue : 'A' + digitValue - 10;
                digits.add(digit);
            }
            for (int i = digits.size() - 1; i >= 0; i--) {
                sb.codePoint(digits.get(i));
            }
        }
        return sb.build();
    }

    public static String hex(int value) {
        return fromIntWithBase(value, 16);
    }
}
