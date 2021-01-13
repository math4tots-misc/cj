package crossj.cj;

public final class CJIRAugmentedAssignment extends CJIRExpression {
    private final CJIRLocalVariableDeclaration target;
    private final CJIRAugAssignKind kind;
    private final CJIRExpression expression;

    CJIRAugmentedAssignment(CJAstExpression ast, CJIRType type, CJIRLocalVariableDeclaration target,
            CJIRAugAssignKind kind, CJIRExpression expression) {
        super(ast, type);
        this.target = target;
        this.kind = kind;
        this.expression = expression;
    }

    public CJIRLocalVariableDeclaration getTarget() {
        return target;
    }

    public CJIRAugAssignKind getKind() {
        return kind;
    }

    public CJIRExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAugmentedAssignment(this, a);
    }
}
