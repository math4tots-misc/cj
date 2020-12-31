package crossj.books.dragon.ch03;

final class QuestionMarkRegexNode implements RegexNode {
    public static final int BINDING_PRECEDENCE = StarRegexNode.BINDING_PRECEDENCE;

    private final RegexNode inner;
    private final IntervalRegexNode proxy;

    QuestionMarkRegexNode(RegexNode inner) {
        this.inner = inner;
        this.proxy = new IntervalRegexNode(inner, 0, 1);
    }

    @Override
    public int getBindingPrecedence() {
        return BINDING_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        return RegexNodeHelper.wrap(inner, BINDING_PRECEDENCE) + "?";
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        proxy.buildBlock(builder, startState, acceptState);
    }
}
