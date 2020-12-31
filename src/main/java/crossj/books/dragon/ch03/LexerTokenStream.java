package crossj.books.dragon.ch03;

import crossj.base.Deque;
import crossj.base.Func1;
import crossj.base.List;
import crossj.base.Try;

final class LexerTokenStream<Token> implements TokenStream<Token> {
    private final RegexMatcher matcher;
    private final List<Func1<Try<List<Token>>, RegexMatcher>> callbacks;
    private final Deque<Token> buffer;
    private Try<Token> error;

    LexerTokenStream(RegexMatcher matcher, List<Func1<Try<List<Token>>, RegexMatcher>> callbacks) {
        this.matcher = matcher;
        this.callbacks = callbacks;
        this.buffer = Deque.of();
        this.error = null;
    }

    private void prepare() {
        while (error == null && buffer.size() == 0 && matcher.getStrIter().hasCodePoint()) {
            if (matcher.match()) {
                var matchIndex = matcher.getMatchIndex();
                if (matcher.atZeroLengthMatch()) {
                    error = Try.fail("Zero length match at " + matcher.getStrIter().getPosition());
                } else {
                    var tryTokenList = callbacks.get(matchIndex).apply(matcher);
                    if (tryTokenList.isFail()) {
                        error = tryTokenList.castFail();
                    } else {
                        buffer.addAll(tryTokenList.get());
                    }
                }
            } else {
                error = Try.fail("Failed to match token at " + matcher.getStrIter().getPosition());
            }
        }
    }

    @Override
    public Try<Token> peek() {
        prepare();
        if (error != null) {
            return error;
        }
        return Try.ok(buffer.get(0));
    }

    @Override
    public Try<Token> next() {
        if (error != null) {
            return error;
        } else {
            return Try.ok(buffer.popLeft());
        }
    }

    @Override
    public boolean hasNext() {
        prepare();
        return buffer.size() > 0 || matcher.getStrIter().hasCodePoint();
    }
}
