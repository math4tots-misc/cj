package crossj.books.dragon.ch03;

import crossj.base.Func1;
import crossj.base.List;
import crossj.base.Try;

public final class Lexer<Token> {

    public static <Token> LexerBuilder<Token> builder() {
        return new LexerBuilder<>();
    }

    private final Regex regex;
    private final List<Func1<Try<List<Token>>, RegexMatcher>> callbacks;

    Lexer(Regex regex, List<Func1<Try<List<Token>>, RegexMatcher>> callbacks) {
        this.regex = regex;
        this.callbacks = callbacks;
    }

    public Try<List<Token>> lexAll(String string) {
        var tokens = List.<Token>of();
        var matcher = regex.matcher(string);
        while (matcher.match()) {
            var matchIndex = matcher.getMatchIndex();
            if (matcher.atZeroLengthMatch()) {
                return Try.<List<Token>>fail("Zero length match (pattern " + matchIndex + ")")
                        .withContext("while lexing " + string);
            }
            var tryTokenList = callbacks.get(matchIndex).apply(matcher);
            if (tryTokenList.isFail()) {
                return tryTokenList;
            }
            tokens.addAll(tryTokenList.get());
        }
        if (matcher.getStrIter().hasCodePoint()) {
            return Try.fail("Unrecognized token on " + matcher.getCurrentLineNumber() + ":" + matcher.getCurrentColumnNumber());
        }
        return Try.ok(tokens);
    }

    public TokenStream<Token> lex(String string) {
        return new LexerTokenStream<>(regex.matcher(string), callbacks);
    }

    public int[] getSerializedDFA() {
        return regex.getDfa().toIntArray();
    }
}
