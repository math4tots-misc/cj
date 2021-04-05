package crossj.cj;

import crossj.cj.ast.CJAstExpression;

public final class CJIRLogicalNot extends CJIRExpression {
    private final CJIRExpression inner;

    CJIRLogicalNot(CJAstExpression ast, CJIRType type, CJIRExpression inner) {
        super(ast, type);
        this.inner = inner;
    }

    public CJIRExpression getInner() {
        return inner;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLogicalNot(this, a);
    }
}
