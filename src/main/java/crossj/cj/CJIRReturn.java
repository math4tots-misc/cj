package crossj.cj;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRReturn extends CJIRExpression {
    private final CJIRExpression expression;

    CJIRReturn(CJAstExpression ast, CJIRType type, CJIRExpression expression) {
        super(ast, type);
        this.expression = expression;
    }

    public CJIRExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitReturn(this, a);
    }
}
