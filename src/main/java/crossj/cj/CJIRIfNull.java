package crossj.cj;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRIfNull extends CJIRExpression {
    private final boolean mutable;
    private final CJIRAssignmentTarget target;
    private final CJIRExpression expression;
    private final CJIRExpression left;
    private final CJIRExpression right;

    public CJIRIfNull(CJAstExpression ast, CJIRType type, boolean mutable, CJIRAssignmentTarget target, CJIRExpression expression,
            CJIRExpression left, CJIRExpression right) {
        super(ast, type);
        this.mutable = mutable;
        this.target = target;
        this.expression = expression;
        this.left = left;
        this.right = right;
    }

    public boolean isMutable() {
        return mutable;
    }

    public CJIRAssignmentTarget getTarget() {
        return target;
    }

    public CJIRExpression getExpression() {
        return expression;
    }

    public CJIRExpression getLeft() {
        return left;
    }

    public CJIRExpression getRight() {
        return right;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitIfNull(this, a);
    }
}
