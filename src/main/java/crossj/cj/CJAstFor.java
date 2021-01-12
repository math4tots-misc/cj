package crossj.cj;

import crossj.base.Optional;

public final class CJAstFor extends CJAstExpression {
    private final CJAstAssignmentTarget target;
    private final CJAstExpression container;
    private final Optional<CJAstExpression> ifCondition;
    private final Optional<CJAstExpression> whileCondition;
    private final CJAstExpression body;

    CJAstFor(CJMark mark, CJAstAssignmentTarget target, CJAstExpression container,
            Optional<CJAstExpression> ifCondition, Optional<CJAstExpression> whileCondition, CJAstExpression body) {
        super(mark);
        this.target = target;
        this.container = container;
        this.ifCondition = ifCondition;
        this.whileCondition = whileCondition;
        this.body = body;
    }

    public CJAstAssignmentTarget getTarget() {
        return target;
    }

    public Optional<CJAstExpression> getIfCondition() {
        return ifCondition;
    }

    public Optional<CJAstExpression> getWhileCondition() {
        return whileCondition;
    }

    public CJAstExpression getContainer() {
        return container;
    }

    public CJAstExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitFor(this, a);
    }
}
