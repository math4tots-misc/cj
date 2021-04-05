package crossj.cj;

import crossj.base.List;
import crossj.cj.ast.CJAstExpression;

public final class CJIRBlock extends CJIRExpression {
    private final List<CJIRExpression> expressions;

    public CJIRBlock(CJAstExpression ast, CJIRType type, List<CJIRExpression> expressions) {
        super(ast, type);
        this.expressions = expressions;
    }

    public List<CJIRExpression> getExpressions() {
        return expressions;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitBlock(this, a);
    }
}
