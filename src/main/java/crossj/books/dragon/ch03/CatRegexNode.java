package crossj.books.dragon.ch03;

final class CatRegexNode implements RegexNode {
    public static final int BINDING_PRECEDENCE = 40;

    final RegexNode left;
    final RegexNode right;

    CatRegexNode(RegexNode left, RegexNode right) {
        this.left = left;
        this.right = right;
    }

    @Override
    public int getBindingPrecedence() {
        return BINDING_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        return RegexNodeHelper.wrap(left, BINDING_PRECEDENCE) + RegexNodeHelper.wrap(right, BINDING_PRECEDENCE);
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        var leftBlock = builder.buildBlock(left, startState, -1);
        builder.buildBlock(right, leftBlock.acceptState, acceptState);
    }
}
