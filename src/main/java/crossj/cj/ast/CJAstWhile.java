package crossj.cj.ast;

import crossj.cj.CJMark;

public final class CJAstWhile extends CJAstExpression {
    private final CJAstExpression condition;
    private final CJAstExpression body;

    public CJAstWhile(CJMark mark, CJAstExpression condition, CJAstExpression body) {
        super(mark);
        this.condition = condition;
        this.body = body;
    }

    public CJAstExpression getCondition() {
        return condition;
    }

    public CJAstExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitWhile(this, a);
    }
}
