package crossj.cj;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRAssignment extends CJIRExpression {
    private final String variableName;
    private final CJIRExpression expression;

    CJIRAssignment(CJAstExpression ast, CJIRType type, String variableName, CJIRExpression expression) {
        super(ast, type);
        this.variableName = variableName;
        this.expression = expression;
    }

    public String getVariableName() {
        return variableName;
    }

    public CJIRExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitAssignment(this, a);
    }
}
