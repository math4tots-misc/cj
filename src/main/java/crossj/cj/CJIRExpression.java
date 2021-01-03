package crossj.cj;

public abstract class CJIRExpression extends CJIRNode<CJAstExpression> {
    private final CJIRType type;

    CJIRExpression(CJAstExpression ast, CJIRType type) {
        super(ast);
        this.type = type;
    }

    public final CJIRType getType() {
        return type;
    }

    public abstract <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a);

    /**
     * If true, introduces a free var into the surrounding scope.
     */
    public boolean introducesFreeVar() {
        return false;
    }
}
