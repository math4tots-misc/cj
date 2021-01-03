package crossj.cj;

public final class CJAstAssignment extends CJAstExpression {
    private final CJAstAssignmentTarget target;
    private final CJAstExpression expression;

    CJAstAssignment(CJMark mark, CJAstAssignmentTarget target, CJAstExpression expression) {
        super(mark);
        this.target = target;
        this.expression = expression;
    }

    public CJAstAssignmentTarget getTarget() {
        return target;
    }

    public CJAstExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAssignment(this, a);
    }
}
