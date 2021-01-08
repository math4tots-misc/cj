package crossj.cj;

public final class CJIRIs extends CJIRExpression {
    private final CJIRExpression left;
    private final CJIRExpression right;

    CJIRIs(CJAstExpression ast, CJIRType type, CJIRExpression left, CJIRExpression right) {
        super(ast, type);
        this.left = left;
        this.right = right;
    }

    public CJIRExpression getLeft() {
        return left;
    }

    public CJIRExpression getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitIs(this, a);
    }
}
