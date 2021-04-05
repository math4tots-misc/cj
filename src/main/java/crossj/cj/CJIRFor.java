package crossj.cj;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRFor extends CJIRExpression {
    private final CJIRAssignmentTarget target;
    private final CJIRExpression iterator;
    private final CJIRExpression body;

    CJIRFor(CJAstExpression ast, CJIRType type, CJIRAssignmentTarget target, CJIRExpression iterator,
            CJIRExpression body) {
        super(ast, type);
        this.target = target;
        this.iterator = iterator;
        this.body = body;
    }

    public CJIRAssignmentTarget getTarget() {
        return target;
    }

    public CJIRExpression getIterator() {
        return iterator;
    }

    public CJIRExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitFor(this, a);
    }
}
