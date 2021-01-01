package crossj.cj;

import crossj.base.List;

public final class CJIRMethodCall extends CJIRExpression {
    private final CJIRType owner;
    private final CJIRMethod method;
    private final List<CJIRType> typeArgs;
    private final List<CJIRExpression> args;

    public CJIRMethodCall(CJAstExpression ast, CJIRType type, CJIRType owner, CJIRMethod method,
            List<CJIRType> typeArgs, List<CJIRExpression> args) {
        super(ast, type);
        this.owner = owner;
        this.method = method;
        this.typeArgs = typeArgs;
        this.args = args;
    }

    public CJIRType getOwner() {
        return owner;
    }

    public CJIRMethod getMethod() {
        return method;
    }

    public List<CJIRType> getTypeArgs() {
        return typeArgs;
    }

    public List<CJIRExpression> getArgs() {
        return args;
    }
}
