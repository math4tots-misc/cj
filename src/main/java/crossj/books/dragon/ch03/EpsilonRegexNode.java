package crossj.books.dragon.ch03;

import crossj.base.Optional;

final class EpsilonRegexNode implements RegexNode {
    public static final int BINDING_PRECEDENCE = LetterRegexNode.BINIDNG_PRECEDENCE;

    @Override
    public int getBindingPrecedence() {
        return BINDING_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        return "";
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        builder.connect(startState, Optional.empty(), acceptState);
    }
}
