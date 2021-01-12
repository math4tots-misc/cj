package crossj.cj;

import crossj.base.Optional;

public final class CJIRFor extends CJIRExpression {
    private final CJIRAssignmentTarget target;
    private final CJIRExpression iterator;
    private final Optional<CJIRExpression> condition;
    private final CJIRExpression body;

    CJIRFor(CJAstExpression ast, CJIRType type, CJIRAssignmentTarget target, CJIRExpression iterator,
            Optional<CJIRExpression> condition, CJIRExpression body) {
        super(ast, type);
        this.target = target;
        this.iterator = iterator;
        this.condition = condition;
        this.body = body;
    }

    public CJIRAssignmentTarget getTarget() {
        return target;
    }

    public Optional<CJIRExpression> getCondition() {
        return condition;
    }

    public CJIRExpression getIterator() {
        return iterator;
    }

    public CJIRExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitFor(this, a);
    }
}
