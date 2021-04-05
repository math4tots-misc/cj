package crossj.cj;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRWhile extends CJIRExpression {
    private final CJIRExpression condition;
    private final CJIRExpression body;

    public CJIRWhile(CJAstExpression ast, CJIRType type, CJIRExpression condition, CJIRExpression body) {
        super(ast, type);
        this.condition = condition;
        this.body = body;
    }

    public CJIRExpression getCondition() {
        return condition;
    }

    public CJIRExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitWhile(this, a);
    }
}
