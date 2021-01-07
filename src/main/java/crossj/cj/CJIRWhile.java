package crossj.cj;

public final class CJIRWhile extends CJIRExpression {
    private final CJIRExpression condition;
    private final CJIRExpression body;

    CJIRWhile(CJAstExpression ast, CJIRType type, CJIRExpression condition, CJIRExpression body) {
        super(ast, type);
        this.condition = condition;
        this.body = body;
    }

    public CJIRExpression getCondition() {
        return condition;
    }

    public CJIRExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitWhile(this, a);
    }
}
