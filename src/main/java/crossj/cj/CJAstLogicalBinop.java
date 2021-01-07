package crossj.cj;

public final class CJAstLogicalBinop extends CJAstExpression {
    private final boolean andType;
    private final CJAstExpression left;
    private final CJAstExpression right;

    CJAstLogicalBinop(CJMark mark, boolean andType, CJAstExpression left, CJAstExpression right) {
        super(mark);
        this.andType = andType;
        this.left = left;
        this.right = right;
    }

    public boolean isAnd() {
        return andType;
    }

    public boolean isOr() {
        return !isAnd();
    }

    public CJAstExpression getLeft() {
        return left;
    }

    public CJAstExpression getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLogicalBinop(this, a);
    }
}
