package crossj.cj;

public final class CJAstAwait extends CJAstExpression {
    private final CJAstExpression inner;

    CJAstAwait(CJMark mark, CJAstExpression inner) {
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
