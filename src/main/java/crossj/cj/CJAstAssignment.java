package crossj.cj;

public final class CJAstAssignment extends CJAstExpression {
    private final String variableName;
    private final CJAstExpression expression;

    CJAstAssignment(CJMark mark, String variableName, CJAstExpression expression) {
        super(mark);
        this.variableName = variableName;
        this.expression = expression;
    }

    public String getVariableName() {
        return variableName;
    }

    public CJAstExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAssignment(this, a);
    }
}
