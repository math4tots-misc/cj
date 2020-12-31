package crossj.books.dragon.ch03;

import crossj.base.Func1;
import crossj.base.List;
import crossj.base.Try;

public final class LexerBuilder<Token> {
    private List<String> patterns = List.of();
    private List<Func1<Try<List<Token>>, RegexMatcher>> callbacks = List.of();
    private int[] precomputedDFA = null;

    LexerBuilder() {
    }

    public LexerBuilder<Token> add(String pattern, Func1<Try<List<Token>>, RegexMatcher> f) {
        patterns.add(pattern);
        callbacks.add(f);
        return this;
    }

    /**
     * This allows using a precomputed DFA when constructing the lexer rather than
     * recreating the entire lexer form scratch which generally tends to be fairly
     * expensive.
     */
    public void setPrecomputedDFA(int[] precomputedDFA) {
        this.precomputedDFA = precomputedDFA;
    }

    public Try<Lexer<Token>> build() {
        Regex regex = null;
        if (precomputedDFA == null) {
            var tryRegex = Regex.fromPatternList(patterns);
            if (tryRegex.isFail()) {
                return tryRegex.castFail();
            }
            regex = tryRegex.get();
        } else {
            regex = Regex.fromIntArray(precomputedDFA);
        }
        return Try.ok(new Lexer<Token>(regex, callbacks));
    }
}
