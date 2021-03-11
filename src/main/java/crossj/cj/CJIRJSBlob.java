package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;

public final class CJIRJSBlob extends CJIRExpression {
    private final List<Object> parts;

    public CJIRJSBlob(CJAstExpression ast, CJIRType type, List<Object> parts) {
        super(ast, type);
        this.parts = parts;
        Assert.that(parts.all(p -> p instanceof String || p instanceof CJIRExpression));
    }

    public List<Object> getParts() {
        return parts;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitJSBlob(this, a);
    }
}