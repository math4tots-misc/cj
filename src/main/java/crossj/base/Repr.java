package crossj.base;

import crossj.cj.CJError;

public interface Repr {
    String repr();

    public static String of(Object x) {
        if (x == null) {
            return "null";
        } else if (x instanceof String) {
            return reprstr((String) x);
        } else if (x instanceof Repr) {
            return ((Repr) x).repr();
        } else {
            return x.toString();
        }
    }

    public static String reprchar(int codePoint) {
        return reprstr(Str.fromCodePoint(codePoint));
    }

    public static String reprstr(String s) {
        var sb = Str.builder();
        sb.c('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\t': sb.s("\\t"); break;
                case '\r': sb.s("\\r"); break;
                case '\n': sb.s("\\n"); break;
                case '\0': sb.s("\\0"); break;
                case '\\': sb.s("\\\\"); break;
                case '\"': sb.s("\\\""); break;
                case '\'': sb.s("\\\'"); break;
                default:
                    if (c < 32 || c == 127) {
                        // non-printable ASCII
                        sb.s("\\x").s(Str.lpad(Str.hex(c), 2, "0"));
                    } else {
                        sb.c(c);
                    }
            }
        }
        sb.c('"');
        return sb.build();
    }

    public static String parse(String s) {
        var sb = Str.builder();
        Assert.equals(s.charAt(0), '"');
        Assert.equals(s.charAt(s.length() - 1), '"');
        for (int i = 1; i < s.length() - 1;) {
            char c = s.charAt(i++);
            if (c == '\\') {
                c = s.charAt(i++);
                switch (c) {
                    case 't': sb.c('\t'); break;
                    case 'r': sb.c('\r'); break;
                    case 'n': sb.c('\n'); break;
                    case '0': sb.c('\0'); break;
                    case '\\': sb.c('\\'); break;
                    case '"': sb.c('"'); break;
                    case '\'': sb.c('\''); break;
                    case 'x': {
                        int value = parseDigit(s.charAt(i++)) * 16;
                        value += parseDigit(s.charAt(i++));
                        sb.c((char) value);
                        break;
                    }
                    default:
                        throw CJError.of("Unrecognized string escape " + Repr.of(c));
                }
            } else {
                sb.c(c);
            }
        }
        return sb.build();
    }

    private static int parseDigit(char digit) {
        if (digit >= '0' && digit <= '9') {
            return digit - '0';
        } else if (digit >= 'A' && digit <= 'Z') {
            return digit - 'A' + 10;
        } else if (digit >= 'a' && digit <= 'z') {
            return digit - 'a' + 10;
        } else {
            throw CJError.of("Invalid digit " + Repr.of(digit));
        }
    }
}
