package crossj.books.dragon.ch03;

import crossj.base.Try;

public interface TokenStream<Token> {
    Try<Token> peek();
    Try<Token> next();
    boolean hasNext();
}
