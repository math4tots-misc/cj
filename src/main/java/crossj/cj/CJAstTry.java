package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple3;

public final class CJAstTry extends CJAstExpression {
    private final CJAstExpression body;
    private final List<Tuple3<CJAstAssignmentTarget, CJAstTypeExpression, CJAstExpression>> clauses;
    private final Optional<CJAstExpression> fin;

    CJAstTry(CJMark mark, CJAstExpression body,
            List<Tuple3<CJAstAssignmentTarget, CJAstTypeExpression, CJAstExpression>> clauses,
            Optional<CJAstExpression> fin) {
        super(mark);
        this.body = body;
        this.clauses = clauses;
        this.fin = fin;
    }

    public CJAstExpression getBody() {
        return body;
    }

    public List<Tuple3<CJAstAssignmentTarget, CJAstTypeExpression, CJAstExpression>> getClauses() {
        return clauses;
    }

    public Optional<CJAstExpression> getFin() {
        return fin;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitTry(this, a);
    }
}
