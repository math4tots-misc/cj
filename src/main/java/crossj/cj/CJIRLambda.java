package crossj.cj;

import crossj.base.List;

public final class CJIRLambda extends CJIRExpression {
    private final List<CJIRAdHocVariableDeclaration> parameters;
    private final CJIRExpression body;

    CJIRLambda(CJAstExpression ast, CJIRType type, List<CJIRAdHocVariableDeclaration> parameters, CJIRExpression body) {
        super(ast, type);
        this.parameters = parameters;
        this.body = body;
    }

    public List<CJIRAdHocVariableDeclaration> getParameters() {
        return parameters;
    }

    public CJIRExpression getBody() {
        return body;
    }

    public CJIRType getReturnType() {
        return body.getType();
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLambda(this, a);
    }
}
