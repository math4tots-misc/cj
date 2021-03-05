package crossj.cj;

import crossj.base.List;
import crossj.base.Try;
import crossj.books.dragon.ch03.Lexer;
import crossj.books.dragon.ch03.RegexMatcher;

public final class CJLexer {
    private static final Lexer<CJToken> lexer = buildLexer();

    private static Lexer<CJToken> buildLexer() {
        var b = Lexer.<CJToken>builder();
        b.add("(\\d+\\.\\d*|\\.\\d+)(e|E-?\\d+)?", m -> tok(CJToken.DOUBLE, m));
        b.add("\\d+(e|E)-?\\d+", m -> tok(CJToken.DOUBLE, m));
        b.add("0x[0-9A-Fa-f]+n", m -> tok(CJToken.BIGINT, m)); // hex literals
        b.add("\\d+n", m -> tok(CJToken.BIGINT, m));
        b.add("0x[0-9A-Fa-f]+", m -> tok(CJToken.INT, m)); // hex literals
        b.add("\\d+", m -> tok(CJToken.INT, m));
        for (int type : CJToken.KEYWORD_TYPES) {
            b.add(CJToken.keywordTypeToString(type), m -> tok(type, m));
        }
        b.add("[A-Z]\\w*", m -> tok(CJToken.TYPE_ID, m));
        b.add("[a-z_]\\w*", m -> tok(CJToken.ID, m));
        b.add("[a-z_]\\w*!", m -> tok(CJToken.MACROID, m));
        b.add("'\\\\.'", m -> tok(CJToken.CHAR, m));
        b.add("'[^'\\\\]'", m -> tok(CJToken.CHAR, m));
        b.add("\"(\\\\.|[^\"\\\\])*\"", m -> tok(CJToken.STRING, m));

        // single character symbol tokens
        b.add("\\(|\\)|\\{|\\}|\\[|\\]|\\+|\\*|/|-|%|~|\\.|^|&|\\||!|@|=|;|,|:|<|>|\\?", m -> chartok(m));

        // multi-character symbol tokens
        b.add("\\.\\.", m -> symtok(CJToken.DOTDOT, m));
        b.add("==", m -> symtok(CJToken.EQ, m));
        b.add("!=", m -> symtok(CJToken.NE, m));
        b.add("<=", m -> symtok(CJToken.LE, m));
        b.add(">=", m -> symtok(CJToken.GE, m));
        b.add("<<", m -> symtok(CJToken.LSHIFT, m));
        b.add(">>", m -> symtok(CJToken.RSHIFT, m));
        b.add(">>>", m -> symtok(CJToken.RSHIFTU, m));
        b.add("//", m -> symtok(CJToken.TRUNCDIV, m));
        b.add("->", m -> symtok(CJToken.RIGHT_ARROW, m));
        b.add("\\*\\*", m -> symtok(CJToken.POWER, m));
        b.add("\\+\\+", m -> symtok(CJToken.PLUSPLUS, m));
        b.add("--", m -> symtok(CJToken.MINUSMINUS, m));
        b.add("\\+=", m -> symtok(CJToken.PLUS_EQ, m));
        b.add("-=", m -> symtok(CJToken.MINUS_EQ, m));
        b.add("\\*=", m -> symtok(CJToken.STAR_EQ, m));
        b.add("%=", m -> symtok(CJToken.REM_EQ, m));

        // newline
        b.add("\n\\s*", m -> chartok(m));

        // comments
        b.add("##[^\n]*(\n\\s*##[^\n]*)*", m -> tok(CJToken.COMMENT, m));
        b.add("#[^\n]*(\n\\s*#[^\n]*)*", m -> none());

        // whitespace
        b.add("[^\\S\n]+", m -> none());

        // NOTE: this must be updated whenever the grammar changes.
        // b.setPrecomputedDFA(CJLexerPrecomputed.DFA);

        var lexer = b.build().get();
        // var dfa = lexer.getSerializedDFA();
        // IO.println("LENGTH = " + dfa.length);
        // IO.println(IntArray.fromJavaIntArray(dfa));
        // throw XError.withMessage("EXIT");
        return lexer;
    }

    public static Try<List<CJToken>> lex(String string) {
        var tryTokens = lexer.lexAll(string);
        if (tryTokens.isFail()) {
            return tryTokens;
        }

        var rawTokens = tryTokens.get();
        int line = 1;
        if (rawTokens.size() > 0) {
            line = rawTokens.last().line + 1;
        }
        rawTokens.add(CJToken.of(CJToken.EOF, "", line, 1));

        // we filter out newline tokens inside pairs of '()' or '[]' tokens
        // but not '{}'.
        var newTokens = List.<CJToken>of();
        var stack = List.<Integer>of();
        for (var token : rawTokens) {
            switch (token.type) {
                case '(':
                case '[':
                case '{':
                    stack.add(token.type);
                    break;
                case ')':
                case ']':
                case '}':
                    if (stack.size() > 0) {
                        stack.pop();
                    }
                    break;
            }
            if (token.type != '\n' || stack.size() == 0 || stack.last() == '{') {
                newTokens.add(token);
            }
        }

        return Try.ok(newTokens);
    }

    private static Try<List<CJToken>> chartok(RegexMatcher m) {
        int type = m.getFirstCodePointOfMatch();
        return Try.ok(List.of(CJToken.of(type, "", m.getMatchLineNumber(), m.getMatchColumnNumber())));
    }

    private static Try<List<CJToken>> tok(int type, RegexMatcher m) {
        return Try.ok(List.of(CJToken.of(type, m.getMatchText(), m.getMatchLineNumber(), m.getMatchColumnNumber())));
    }

    private static Try<List<CJToken>> symtok(int type, RegexMatcher m) {
        return Try.ok(List.of(CJToken.of(type, "", m.getMatchLineNumber(), m.getMatchColumnNumber())));
    }

    private static Try<List<CJToken>> none() {
        return Try.ok(List.of());
    }
}
