package crossj.books.dragon.ch03;

final class StarRegexNode implements RegexNode {
    public static final int BINDING_PRECEDENCE = 50;

    private final RegexNode inner;
    private final IntervalRegexNode proxy;

    StarRegexNode(RegexNode inner) {
        this.inner = inner;
        this.proxy = new IntervalRegexNode(inner, 0, -1);
    }

    @Override
    public String toString() {
        return inner + "*";
    }

    @Override
    public int getBindingPrecedence() {
        return BINDING_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        return RegexNodeHelper.wrap(inner, BINDING_PRECEDENCE) + "*";
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        proxy.buildBlock(builder, startState, acceptState);
    }
}
