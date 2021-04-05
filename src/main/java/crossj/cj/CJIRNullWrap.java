package crossj.cj;

import crossj.base.Optional;
import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRNullWrap extends CJIRExpression {
    private final Optional<CJIRExpression> inner;

    public CJIRNullWrap(CJAstExpression ast, CJIRType type, Optional<CJIRExpression> inner) {
        super(ast, type);
        this.inner = inner;
    }

    public Optional<CJIRExpression> getInner() {
        return inner;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitNullWrap(this, a);
    }
}
