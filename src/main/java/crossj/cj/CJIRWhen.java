package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple5;
import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRWhen extends CJIRExpression {
    private final CJIRExpression target;
    private final List<Tuple5<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, Boolean, CJIRExpression>> cases;
    private final Optional<CJIRExpression> fallback;

    CJIRWhen(CJAstExpression ast, CJIRType type, CJIRExpression target,
            List<Tuple5<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, Boolean, CJIRExpression>> cases,
            Optional<CJIRExpression> fallback) {
        super(ast, type);
        this.target = target;
        this.cases = cases;
        this.fallback = fallback;
    }

    public CJIRExpression getTarget() {
        return target;
    }

    public List<Tuple5<CJMark, CJIRCase, List<CJIRAdHocVariableDeclaration>, Boolean, CJIRExpression>> getCases() {
        return cases;
    }

    public Optional<CJIRExpression> getFallback() {
        return fallback;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitWhen(this, a);
    }
}
