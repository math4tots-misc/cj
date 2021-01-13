package crossj.cj;

import crossj.base.List;

public final class CJAstTupleDisplay extends CJAstExpression {
    private final List<CJAstExpression> expressions;

    CJAstTupleDisplay(CJMark mark, List<CJAstExpression> expressions) {
        super(mark);
        this.expressions = expressions;
    }

    public List<CJAstExpression> getExpressions() {
        return expressions;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitTupleDisplay(this, a);
    }
}
