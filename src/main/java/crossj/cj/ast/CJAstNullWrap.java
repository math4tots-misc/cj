package crossj.cj.ast;

import crossj.base.Optional;
import crossj.cj.CJMark;

public final class CJAstNullWrap extends CJAstExpression {
    private final Optional<CJAstTypeExpression> innerType;
    private final Optional<CJAstExpression> inner;

    public CJAstNullWrap(CJMark mark, Optional<CJAstTypeExpression> innerType, Optional<CJAstExpression> inner) {
        super(mark);
        this.innerType = innerType;
        this.inner = inner;
    }

    public Optional<CJAstTypeExpression> getInnerType() {
        return innerType;
    }

    public Optional<CJAstExpression> getInner() {
        return inner;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitNullWrap(this, a);
    }
}
