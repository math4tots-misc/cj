package crossj.cj.ir;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRAwait extends CJIRExpression {
    private final CJIRExpression inner;

    public CJIRAwait(CJAstExpression ast, CJIRType type, CJIRExpression inner) {
        super(ast, type);
        this.inner = inner;
    }

    public CJIRExpression getInner() {
        return inner;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAwait(this, a);
    }
}
