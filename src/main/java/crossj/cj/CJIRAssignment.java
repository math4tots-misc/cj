package crossj.cj;

public final class CJIRAssignment extends CJIRExpression {
    private final CJIRAssignmentTarget target;
    private final CJIRExpression expression;

    CJIRAssignment(CJAstExpression ast, CJIRType type, CJIRAssignmentTarget target, CJIRExpression expression) {
        super(ast, type);
        this.target = target;
        this.expression = expression;
    }

    public CJIRAssignmentTarget getTarget() {
        return target;
    }

    public CJIRExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAssignment(this, a);
    }
}
