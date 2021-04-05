package crossj.cj.ast;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Pair;
import crossj.cj.CJMark;

public final class CJAstSwitch extends CJAstExpression {
    private final CJAstExpression target;
    private final List<Pair<List<CJAstExpression>, CJAstExpression>> cases;
    private final Optional<CJAstExpression> fallback;

    public CJAstSwitch(CJMark mark, CJAstExpression target,
            List<Pair<List<CJAstExpression>, CJAstExpression>> cases,
            Optional<CJAstExpression> fallback) {
        super(mark);
        this.target = target;
        this.cases = cases;
        this.fallback = fallback;
    }
    public CJAstExpression getTarget() {
        return target;
    }

    public List<Pair<List<CJAstExpression>, CJAstExpression>> getCases() {
        return cases;
    }

    public Optional<CJAstExpression> getFallback() {
        return fallback;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitSwitch(this, a);
    }
}
