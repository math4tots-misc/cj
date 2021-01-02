package crossj.cj;

import crossj.base.List;

public final class CJIRMethodCall extends CJIRExpression {
    private final CJIRType owner;
    private final CJIRMethodRef methodRef;
    private final List<CJIRType> typeArgs;
    private final List<CJIRExpression> args;

    public CJIRMethodCall(CJAstExpression ast, CJIRType type, CJIRType owner, CJIRMethodRef methodRef,
            List<CJIRType> typeArgs, List<CJIRExpression> args) {
        super(ast, type);
        this.owner = owner;
        this.methodRef = methodRef;
        this.typeArgs = typeArgs;
        this.args = args;
    }

    public CJIRType getOwner() {
        return owner;
    }

    public CJIRMethodRef getMethodRef() {
        return methodRef;
    }

    public String getName() {
        return methodRef.getName();
    }

    public List<CJIRType> getTypeArgs() {
        return typeArgs;
    }

    public List<CJIRExpression> getArgs() {
        return args;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitMethodCall(this, a);
    }
}
