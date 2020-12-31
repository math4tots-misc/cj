package crossj.books.dragon.ch03;

import crossj.base.Optional;
import crossj.base.Str;
import crossj.base.XError;

final class LetterRegexNode implements RegexNode {
    public static final int BINIDNG_PRECEDENCE = 90;

    final int letter;

    LetterRegexNode(int letter) {
        if (letter < 0 || letter >= Alphabet.COUNT) {
            throw XError.withMessage("Only ASCII values are allowed but got: " + Str.fromCodePoint(letter));
        }
        this.letter = letter;
    }

    @Override
    public int getBindingPrecedence() {
        return BINIDNG_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        switch (letter) {
            case (int) '\\': return "\\\\";
            case (int) '(': return "\\(";
            case (int) ')': return "\\)";
            default: return Str.fromCodePoint(letter);
        }
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        builder.connect(startState, Optional.of(letter), acceptState);
    }
}
