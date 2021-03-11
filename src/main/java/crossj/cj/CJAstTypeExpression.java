package crossj.cj;

import crossj.base.List;

public final class CJAstTypeExpression extends CJAstTraitOrTypeExpression {
    CJAstTypeExpression(CJMark mark, String name, List<CJAstTypeExpression> args) {
        super(mark, name, args);
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitType(this, a);
    }
}
