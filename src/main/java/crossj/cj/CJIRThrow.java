package crossj.cj;

public final class CJIRThrow extends CJIRExpression {
    private final CJIRExpression expression;

    CJIRThrow(CJAstExpression ast, CJIRType type, CJIRExpression expression) {
        super(ast, type);
        this.expression = expression;
    }

    public CJIRExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitThrow(this, a);
    }
}
