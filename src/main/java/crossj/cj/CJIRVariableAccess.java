package crossj.cj;

import crossj.cj.ast.CJAstExpression;

public final class CJIRVariableAccess extends CJIRExpression {
    private final CJIRLocalVariableDeclaration declaration;

    public CJIRVariableAccess(CJAstExpression ast, CJIRLocalVariableDeclaration declaration) {
        super(ast, declaration.getVariableType());
        this.declaration = declaration;
    }

    public CJIRLocalVariableDeclaration getDeclaration() {
        return declaration;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitVariableAccess(this, a);
    }
}
