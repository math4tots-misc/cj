package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Pair;
import crossj.base.Tuple3;
import crossj.base.Tuple4;

/**
 * Union expression
 */
public final class CJAstWhen extends CJAstExpression {
    private final CJAstExpression target;
    private final List<Pair<List<Tuple4<CJMark, String, List<Tuple3<CJMark, Boolean, String>>, Boolean>>, CJAstExpression>> cases;
    private final Optional<CJAstExpression> fallback;

    CJAstWhen(CJMark mark, CJAstExpression target,
            List<Pair<List<Tuple4<CJMark, String, List<Tuple3<CJMark, Boolean, String>>, Boolean>>, CJAstExpression>> cases,
            Optional<CJAstExpression> fallback) {
        super(mark);
        this.target = target;
        this.cases = cases;
        this.fallback = fallback;
    }

    public CJAstExpression getTarget() {
        return target;
    }

    public List<Pair<List<Tuple4<CJMark, String, List<Tuple3<CJMark, Boolean, String>>, Boolean>>, CJAstExpression>> getCases() {
        return cases;
    }

    public Optional<CJAstExpression> getFallback() {
        return fallback;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitWhen(this, a);
    }
}
