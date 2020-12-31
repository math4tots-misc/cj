package crossj.base;

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
}
