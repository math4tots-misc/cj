package crossj.cj.ast;

import crossj.base.Optional;
import crossj.cj.CJMark;

public final class CJAstVariableDeclaration extends CJAstExpression {
    private final boolean mutable;
    private final CJAstAssignmentTarget target;
    private final Optional<CJAstTypeExpression> declaredType;
    private final CJAstExpression expression;

    public CJAstVariableDeclaration(CJMark mark, boolean mutable, CJAstAssignmentTarget target,
            Optional<CJAstTypeExpression> declaredType, CJAstExpression expression) {
        super(mark);
        this.mutable = mutable;
        this.target = target;
        this.declaredType = declaredType;
        this.expression = expression;
    }

    public boolean isMutable() {
        return mutable;
    }

    public CJAstAssignmentTarget getTarget() {
        return target;
    }

    public Optional<CJAstTypeExpression> getDeclaredType() {
        return declaredType;
    }

    public CJAstExpression getExpression() {
        return expression;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitVariableDeclaration(this, a);
    }
}
