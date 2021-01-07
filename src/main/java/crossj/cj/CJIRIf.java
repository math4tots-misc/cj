package crossj.cj;

public final class CJIRIf extends CJIRExpression {
    private final CJIRExpression condition;
    private final CJIRExpression left;
    private final CJIRExpression right;

    CJIRIf(CJAstExpression ast, CJIRType type, CJIRExpression condition, CJIRExpression left, CJIRExpression right) {
        super(ast, type);
        this.condition = condition;
        this.left = left;
        this.right = right;
    }

    public CJIRExpression getCondition() {
        return condition;
    }

    public CJIRExpression getLeft() {
        return left;
    }

    public CJIRExpression getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitIf(this, a);
    }
}
