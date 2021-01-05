package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple3;
import crossj.base.Tuple4;

/**
 * Union expression
 */
public final class CJAstUnion extends CJAstExpression {
    private final CJAstExpression target;
    private final List<Tuple4<CJMark, String, List<Tuple3<CJMark, Boolean, String>>, CJAstExpression>> cases;
    private final Optional<CJAstExpression> fallback;

    CJAstUnion(CJMark mark, CJAstExpression target,
            List<Tuple4<CJMark, String, List<Tuple3<CJMark, Boolean, String>>, CJAstExpression>> cases,
            Optional<CJAstExpression> fallback) {
        super(mark);
        this.target = target;
        this.cases = cases;
        this.fallback = fallback;
    }

    public CJAstExpression getTarget() {
        return target;
    }

    public List<Tuple4<CJMark, String, List<Tuple3<CJMark, Boolean, String>>, CJAstExpression>> getCases() {
        return cases;
    }

    public Optional<CJAstExpression> getFallback() {
        return fallback;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitUnion(this, a);
    }
}