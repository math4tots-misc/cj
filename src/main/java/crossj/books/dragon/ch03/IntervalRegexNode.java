package crossj.books.dragon.ch03;

import crossj.base.Assert;
import crossj.base.Optional;

final class IntervalRegexNode implements RegexNode {
    public static final int BINDING_PRECEDENCE = StarRegexNode.BINDING_PRECEDENCE;

    private final RegexNode inner;
    private final int min;
    private final int max;

    IntervalRegexNode(RegexNode inner, int min, int max) {
        Assert.withMessage(min >= 0, "min in IntervalRegexNode must be non-negative");
        Assert.withMessage(max == -1 || min <= max, "min must be less than or equal to max in IntervalRegexNode");
        this.inner = inner;
        this.min = min;
        this.max = max;
    }

    @Override
    public int getBindingPrecedence() {
        return BINDING_PRECEDENCE;
    }

    @Override
    public String toPattern() {
        var suffix = min == max ? "{" + min + "}" : max == -1 ? "{" + min + ",}" : "{" + min + "," + max + "}";
        return RegexNodeHelper.wrap(inner, BINDING_PRECEDENCE) + suffix;
    }

    @Override
    public void buildBlock(NFABuilder builder, int startState, int acceptState) {
        switch (max) {
            case -1:
                if (min == 0) {
                    // case 1: max is infinite and min = 0
                    // this is equivalent to '*' (kleene star)
                    builder.buildBlock(inner, startState, acceptState);
                    builder.connect(startState, Optional.empty(), acceptState);
                    builder.connect(acceptState, Optional.empty(), startState);
                } else {
                    // case 2: max is infinite and min > 0
                    // we build min blocks, with the last one using the overall acceptState
                    // as its acceptState.
                    // when min = 1, this is equivalent to '+'
                    for (int i = 0; i + 1 < min; i++) {
                        startState = builder.buildBlock(inner, startState, -1).acceptState;
                    }
                    builder.buildBlock(inner, startState, acceptState);
                    builder.connect(acceptState, Optional.empty(), startState);
                }
                break;
            case 0:
                // case 3: max = 0
                builder.connect(startState, Optional.empty(), acceptState);
                break;
            default:
                // case 4: max is finite, max > 0
                // when min = 0 and max = 1 this is '?'
                for (int i = 0; i < max; i++) {
                    if (i >= min) {
                        builder.connect(startState, Optional.empty(), acceptState);
                    }
                    startState = builder.buildBlock(inner, startState, i + 1 == max ? acceptState : -1).acceptState;
                }
                break;
        }
    }
}
