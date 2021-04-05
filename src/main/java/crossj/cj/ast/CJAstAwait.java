package crossj.cj.ast;

import crossj.cj.CJMark;

public final class CJAstAwait extends CJAstExpression {
    private final CJAstExpression inner;

    public CJAstAwait(CJMark mark, CJAstExpression inner) {
        super(mark);
        this.inner = inner;
    }

    public CJAstExpression getInner() {
        return inner;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAwait(this, a);
    }
}
