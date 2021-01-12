package crossj.cj;

import crossj.base.Optional;

public final class CJIRFor extends CJIRExpression {
    private final CJIRAssignmentTarget target;
    private final CJIRExpression iterator;
    private final Optional<CJIRExpression> ifCondition;
    private final Optional<CJIRExpression> whileCondition;
    private final CJIRExpression body;

    CJIRFor(CJAstExpression ast, CJIRType type, CJIRAssignmentTarget target, CJIRExpression iterator,
            Optional<CJIRExpression> ifCondition, Optional<CJIRExpression> whileCondition, CJIRExpression body) {
        super(ast, type);
        this.target = target;
        this.iterator = iterator;
        this.ifCondition = ifCondition;
        this.whileCondition = whileCondition;
        this.body = body;
    }

    public CJIRAssignmentTarget getTarget() {
        return target;
    }

    public CJIRExpression getIterator() {
        return iterator;
    }

    public Optional<CJIRExpression> getIfCondition() {
        return ifCondition;
    }

    public Optional<CJIRExpression> getWhileCondition() {
        return whileCondition;
    }

    public CJIRExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitFor(this, a);
    }
}
