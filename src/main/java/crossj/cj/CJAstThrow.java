package crossj.cj;

public final class CJAstThrow extends CJAstExpression {
    private final CJAstExpression expression;

    CJAstThrow(CJMark mark, CJAstExpression expression) {
        super(mark);
        this.expression = expression;
    }

    public CJAstExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitThrow(this, a);
    }
}
