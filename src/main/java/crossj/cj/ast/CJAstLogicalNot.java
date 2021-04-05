package crossj.cj.ast;

import crossj.cj.CJMark;

public class CJAstLogicalNot extends CJAstExpression {
    private final CJAstExpression inner;

    public CJAstLogicalNot(CJMark mark, CJAstExpression inner) {
        super(mark);
        this.inner = inner;
    }

    public CJAstExpression getInner() {
        return inner;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLogicalNot(this, a);
    }
}
