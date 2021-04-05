package crossj.cj.ast;

import crossj.base.Optional;
import crossj.cj.CJMark;

public final class CJAstIf extends CJAstExpression {
    private final CJAstExpression condition;
    private final CJAstExpression left;
    private final Optional<CJAstExpression> right;

    public CJAstIf(CJMark mark, CJAstExpression condition, CJAstExpression left, Optional<CJAstExpression> right) {
        super(mark);
        this.condition = condition;
        this.left = left;
        this.right = right;
    }

    public CJAstExpression getCondition() {
        return condition;
    }

    public CJAstExpression getLeft() {
        return left;
    }

    public Optional<CJAstExpression> getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitIf(this, a);
    }
}
