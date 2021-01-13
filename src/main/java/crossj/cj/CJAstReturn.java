package crossj.cj;

public final class CJAstReturn extends CJAstExpression {
    private final CJAstExpression expression;

    CJAstReturn(CJMark mark, CJAstExpression expression) {
        super(mark);
        this.expression = expression;
    }

    public CJAstExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitReturn(this, a);
    }
}
