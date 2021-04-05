package crossj.cj.ast;

import crossj.cj.CJMark;

public final class CJAstIs extends CJAstExpression {
    private final CJAstExpression left;
    private final CJAstExpression right;

    public CJAstIs(CJMark mark, CJAstExpression left, CJAstExpression right) {
        super(mark);
        this.left = left;
        this.right = right;
    }

    public CJAstExpression getLeft() {
        return left;
    }

    public CJAstExpression getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitIs(this, a);
    }
}
