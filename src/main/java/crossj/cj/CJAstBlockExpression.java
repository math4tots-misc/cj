package crossj.cj;

import crossj.base.List;

public final class CJAstBlockExpression extends CJAstExpression {
    private final List<CJAstExpression> statements;

    public CJAstBlockExpression(CJMark mark, List<CJAstExpression> statements) {
        super(mark);
        this.statements = statements;
    }

    public List<CJAstExpression> getStatements() {
        return statements;
    }
}
