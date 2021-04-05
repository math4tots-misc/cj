package crossj.cj;

import crossj.cj.ast.CJAstExpression;

public final class CJIRLogicalBinop extends CJIRExpression {
    private final boolean andType;
    private final CJIRExpression left;
    private final CJIRExpression right;

    CJIRLogicalBinop(CJAstExpression ast, CJIRType type, boolean andType, CJIRExpression left,
            CJIRExpression right) {
        super(ast, type);
        this.andType = andType;
        this.left = left;
        this.right = right;
    }

    /**
     * Indicates that this is an 'and' expression.
     * If false, this is an 'or' expression.
     */
    public boolean isAnd() {
        return andType;
    }

    public CJIRExpression getLeft() {
        return left;
    }

    public CJIRExpression getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLogicalBinop(this, a);
    }
}
