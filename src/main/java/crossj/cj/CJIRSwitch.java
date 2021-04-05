package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Pair;
import crossj.cj.ast.CJAstExpression;

public final class CJIRSwitch extends CJIRExpression {
    private final CJIRExpression target;
    private final List<Pair<List<CJIRExpression>, CJIRExpression>> cases;
    private final Optional<CJIRExpression> fallback;

    CJIRSwitch(CJAstExpression ast, CJIRType type, CJIRExpression target,
            List<Pair<List<CJIRExpression>, CJIRExpression>> cases, Optional<CJIRExpression> fallback) {
        super(ast, type);
        this.target = target;
        this.cases = cases;
        this.fallback = fallback;
    }

    public CJIRExpression getTarget() {
        return target;
    }

    public List<Pair<List<CJIRExpression>, CJIRExpression>> getCases() {
        return cases;
    }

    public Optional<CJIRExpression> getFallback() {
        return fallback;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitSwitch(this, a);
    }
}
