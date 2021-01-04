package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple4;

public final class CJIRUnion extends CJIRExpression {
    private final CJIRExpression target;
    private final List<Tuple4<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, CJIRExpression>> cases;
    private final Optional<CJIRExpression> fallback;

    CJIRUnion(CJAstExpression ast, CJIRType type, CJIRExpression target,
            List<Tuple4<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, CJIRExpression>> cases,
            Optional<CJIRExpression> fallback) {
        super(ast, type);
        this.target = target;
        this.cases = cases;
        this.fallback = fallback;
    }

    public CJIRExpression getTarget() {
        return target;
    }

    public List<Tuple4<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, CJIRExpression>> getCases() {
        return cases;
    }

    public Optional<CJIRExpression> getFallback() {
        return fallback;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitUnion(this, a);
    }
}
