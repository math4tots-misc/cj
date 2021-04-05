package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple3;
import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRTry extends CJIRExpression {
    private final CJIRExpression body;
    private final List<Tuple3<CJIRAssignmentTarget, CJIRType, CJIRExpression>> clauses;
    private final Optional<CJIRExpression> fin;

    public CJIRTry(CJAstExpression ast, CJIRType type, CJIRExpression body,
            List<Tuple3<CJIRAssignmentTarget, CJIRType, CJIRExpression>> clauses, Optional<CJIRExpression> fin) {
        super(ast, type);
        this.body = body;
        this.clauses = clauses;
        this.fin = fin;
    }

    public CJIRExpression getBody() {
        return body;
    }

    public List<Tuple3<CJIRAssignmentTarget, CJIRType, CJIRExpression>> getClauses() {
        return clauses;
    }

    public Optional<CJIRExpression> getFin() {
        return fin;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitTry(this, a);
    }
}
