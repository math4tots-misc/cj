package crossj.cj.ast;

import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJMark;

public final class CJAstMethodCall extends CJAstExpression {
    private final Optional<CJAstTypeExpression> owner;
    private final String name;
    private final List<CJAstTypeExpression> typeArgs;
    private final List<CJAstExpression> args;
    private final boolean receiverOmitted;
    private boolean implicitSelfAdded = false;

    public CJAstMethodCall(CJMark mark, Optional<CJAstTypeExpression> owner, String name, List<CJAstTypeExpression> typeArgs,
            List<CJAstExpression> args, boolean receiverOmitted) {
        super(mark);
        this.owner = owner;
        this.name = name;
        this.typeArgs = typeArgs;
        this.args = args;
        this.receiverOmitted = receiverOmitted;
    }

    public CJAstMethodCall(CJMark mark, Optional<CJAstTypeExpression> owner, String name, List<CJAstTypeExpression> typeArgs,
            List<CJAstExpression> args) {
        this(mark, owner, name, typeArgs, args, false);
    }

    public Optional<CJAstTypeExpression> getOwner() {
        return owner;
    }

    public String getName() {
        return name;
    }

    public List<CJAstTypeExpression> getTypeArgs() {
        return typeArgs;
    }

    public List<CJAstExpression> getArgs() {
        return args;
    }

    public boolean isReceiverOmitted() {
        return receiverOmitted;
    }

    public boolean isImplicitSelfAdded() {
        return implicitSelfAdded;
    }

    public void setImplicitSelfAdded(boolean implicitSelfAdded) {
        this.implicitSelfAdded = implicitSelfAdded;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitMethodCall(this, a);
    }
}
