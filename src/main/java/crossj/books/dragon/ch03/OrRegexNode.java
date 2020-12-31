package crossj.books.dragon.ch03;

import crossj.base.Optional;

final class OrRegexNode implements RegexNode {
    public static final int BINDING_PRECEDENCE = 30;
    final RegexNode left;
    final RegexNode right;

    OrRegexNode(RegexNode left, RegexNode right) {
        this.left = left;
        this.right = right;
    }

    @Override
    public int getBindingPrecedence() {
        return BINDING_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        return left.toPattern() + "|" + right.toPattern();
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        var leftBlock = builder.buildBlock(left, -1, -1);
        var rightBlock = builder.buildBlock(right, -1, -1);
        builder.connect(startState, Optional.empty(), leftBlock.startState);
        builder.connect(startState, Optional.empty(), rightBlock.startState);
        builder.connect(leftBlock.acceptState, Optional.empty(), acceptState);
        builder.connect(rightBlock.acceptState, Optional.empty(), acceptState);
    }
}
