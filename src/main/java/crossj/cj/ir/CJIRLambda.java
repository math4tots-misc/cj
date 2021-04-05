package crossj.cj.ir;

import crossj.base.List;
import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRLambda extends CJIRExpression {
    private final boolean async_;
    private final List<CJIRAdHocVariableDeclaration> parameters;
    private final CJIRExpression body;

    public CJIRLambda(CJAstExpression ast, CJIRType type, boolean async_, List<CJIRAdHocVariableDeclaration> parameters, CJIRExpression body) {
        super(ast, type);
        this.async_ = async_;
        this.parameters = parameters;
        this.body = body;
    }

    public boolean isAsync() {
        return async_;
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
