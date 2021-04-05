package crossj.cj;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public abstract class CJIRExpression extends CJIRNode<CJAstExpression> {
    private final CJIRType type;

    protected CJIRExpression(CJAstExpression ast, CJIRType type) {
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

    public boolean isAlwaysTrue() {
        return false;
    }
}
