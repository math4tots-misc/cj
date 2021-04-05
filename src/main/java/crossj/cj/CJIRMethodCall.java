package crossj.cj;

import crossj.base.List;
import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRMethodCall extends CJIRExpression {
    private final CJIRType owner;
    private final CJIRReifiedMethodRef reifiedMethodRef;
    private final List<CJIRExpression> args;

    public CJIRMethodCall(CJAstExpression ast, CJIRType type, CJIRType owner, CJIRReifiedMethodRef reifiedMethodRef, List<CJIRExpression> args) {
        super(ast, type);
        this.owner = owner;
        this.reifiedMethodRef = reifiedMethodRef;
        this.args = args;
    }

    public CJIRType getOwner() {
        return owner;
    }

    public CJIRReifiedMethodRef getReifiedMethodRef() {
        return reifiedMethodRef;
    }

    public CJIRMethodRef getMethodRef() {
        return reifiedMethodRef.getMethodRef();
    }

    public String getName() {
        return reifiedMethodRef.getName();
    }

    public List<CJIRType> getTypeArgs() {
        return reifiedMethodRef.getTypeArgs();
    }

    public List<CJIRExpression> getArgs() {
        return args;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitMethodCall(this, a);
    }
}
