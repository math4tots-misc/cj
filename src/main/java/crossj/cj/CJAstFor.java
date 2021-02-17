package crossj.cj;

public final class CJAstFor extends CJAstExpression {
    private final CJAstAssignmentTarget target;
    private final CJAstExpression container;
    private final CJAstExpression body;

    CJAstFor(CJMark mark, CJAstAssignmentTarget target, CJAstExpression container, CJAstExpression body) {
        super(mark);
        this.target = target;
        this.container = container;
        this.body = body;
    }

    public CJAstAssignmentTarget getTarget() {
        return target;
    }

    public CJAstExpression getContainer() {
        return container;
    }

    public CJAstExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitFor(this, a);
    }
}
