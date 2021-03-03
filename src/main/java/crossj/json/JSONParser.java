package crossj.json;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Repr;
import crossj.cj.CJError;

class JSONParser {
    static JSON parse(String blob) {
        var parser = new JSONParser(blob);
        var json = parser.parseOne();
        parser.skipSpaces();
        if (parser.i < blob.length()) {
            throw CJError.of("Unexpected end of string in JSON file");
        }
        return json;
    }

    private final String s;
    private int i = 0;

    private JSONParser(String s) {
        this.s = s;
    }

    private void skipSpaces() {
        while (i < s.length() && Character.isWhitespace(s.charAt(i))) {
            i++;
        }
    }

    private boolean consume(char c) {
        if (s.charAt(i) == c) {
            i++;
            return true;
        }
        return false;
    }

    private void expect(char c) {
        if (s.charAt(i++) != c) {
            throw CJError.of("Expected " + Repr.of(c) + " but got " + Repr.of(s.charAt(i - 1)));
        }
    }

    private JSON parseOne() {
        skipSpaces();
        char c = s.charAt(i++);
        switch (c) {
            case 't':
                Assert.that(s.startsWith("rue", i));
                i += 3;
                return JSON.of(true);
            case 'f':
                Assert.that(s.startsWith("alse", i));
                i += 4;
                return JSON.of(false);
            case 'n':
                Assert.that(s.startsWith("ull", i));
                i += 3;
                return JSON.of();
            case '"': return parseRestOfStringLiteral();
            case '[': return parseRestOfArray();
            case '{': return parseRestOfObject();
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
            case '.':
            case '-':
                return parseRestOfNumber(c);
        }
        throw CJError.of("Invalid character while parsing JSON " + Repr.of(c));
    }

    private static boolean isNumberChar(char c) {
        switch (c) {
            case '.':
            case 'e':
            case 'E':
            case '+':
            case '-':
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                return true;
        }
        return false;
    }

    private JSNumber parseRestOfNumber(char firstChar) {
        var sb = new StringBuilder();
        sb.append(firstChar);
        while (i < s.length() && isNumberChar(s.charAt(i))) {
            sb.append(s.charAt(i++));
        }
        return JSON.of(Double.parseDouble(sb.toString()));
    }

    private JSString parseRestOfStringLiteral() {
        int start = i;
        char c = s.charAt(i++);
        while (c != '"') {
            if (c == '\\') {
                i++;
            }
            c = s.charAt(i++);
        }
        return JSON.of(Repr.parse(s.substring(start - 1, i)));
    }

    private JSArray parseRestOfArray() {
        var arr = List.<JSON>of();
        skipSpaces();
        while (!consume(']')) {
            skipSpaces();
            arr.add(parseOne());
            skipSpaces();
            if (!consume(',')) {
                skipSpaces();
                expect(']');
                break;
            }
        }
        return JSON.of(arr);
    }

    private JSObject parseRestOfObject() {
        Map<String, JSON> obj = Map.of();
        skipSpaces();
        while (!consume('}')) {
            skipSpaces();
            expect('"');
            var key = parseRestOfStringLiteral().getString();
            skipSpaces();
            expect(':');
            skipSpaces();
            var value = parseOne();
            obj.put(key, value);
            skipSpaces();
            if (!consume(',')) {
                skipSpaces();
                expect('}');
                break;
            }
        }
        return JSON.of(obj);
    }
}
