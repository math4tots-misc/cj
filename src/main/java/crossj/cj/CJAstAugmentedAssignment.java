package crossj.cj;

public final class CJAstAugmentedAssignment extends CJAstExpression {
    private final String target;
    private final CJIRAugAssignKind kind;
    private final CJAstExpression expression;

    CJAstAugmentedAssignment(CJMark mark, String target, CJIRAugAssignKind kind,
            CJAstExpression expression) {
        super(mark);
        this.target = target;
        this.kind = kind;
        this.expression = expression;
    }

    public String getTarget() {
        return target;
    }

    public CJIRAugAssignKind getKind() {
        return kind;
    }

    public CJAstExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAugmentedAssignment(this, a);
    }
}
