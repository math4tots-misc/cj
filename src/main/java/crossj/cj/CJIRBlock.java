package crossj.cj;

import crossj.base.List;

public final class CJIRBlock extends CJIRExpression {
    private final List<CJIRExpression> expressions;

    public CJIRBlock(CJAstExpression ast, CJIRType type, List<CJIRExpression> expressions) {
        super(ast, type);
        this.expressions = expressions;
    }

    public List<CJIRExpression> getExpressions() {
        return expressions;
    }
}
