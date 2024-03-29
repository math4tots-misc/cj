package crossj.cj.ir;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRTag extends CJIRExpression {
    private final CJIRExpression target;

    public CJIRTag(CJAstExpression ast, CJIRType type, CJIRExpression target) {
        super(ast, type);
        this.target = target;
    }

    public CJIRExpression getTarget() {
        return target;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitTag(this, a);
    }
}
