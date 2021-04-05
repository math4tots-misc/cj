package crossj.cj.ast;

import crossj.base.Optional;
import crossj.cj.CJMark;

public final class CJAstIfNull extends CJAstExpression {
    private final boolean mutable;
    private final CJAstAssignmentTarget target;
    private final CJAstExpression expression;
    private final CJAstExpression left;
    private final Optional<CJAstExpression> right;

    public CJAstIfNull(CJMark mark, boolean mutable, CJAstAssignmentTarget target, CJAstExpression expression,
            CJAstExpression left, Optional<CJAstExpression> right) {
        super(mark);
        this.mutable = mutable;
        this.target = target;
        this.expression = expression;
        this.left = left;
        this.right = right;
    }

    public boolean isMutable() {
        return mutable;
    }

    public CJAstAssignmentTarget getTarget() {
        return target;
    }

    public CJAstExpression getExpression() {
        return expression;
    }

    public CJAstExpression getLeft() {
        return left;
    }

    public Optional<CJAstExpression> getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitIfNull(this, a);
    }
}
