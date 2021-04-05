package crossj.cj.ir;

import crossj.base.Optional;
import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRClassType;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRIsSet extends CJIRExpression {
    private final CJIRClassType ownerType;
    private final Optional<CJIRExpression> owner;
    private final CJIRField field;

    public CJIRIsSet(CJAstExpression ast, CJIRType type, CJIRClassType ownerType, Optional<CJIRExpression> owner,
            CJIRField field) {
        super(ast, type);
        this.ownerType = ownerType;
        this.owner = owner;
        this.field = field;
    }

    public CJIRClassType getOwnerType() {
        return ownerType;
    }

    public Optional<CJIRExpression> getOwner() {
        return owner;
    }

    public CJIRField getField() {
        return field;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitIsSet(this, a);
    }
}
