package crossj.cj;

import crossj.base.List;

public final class CJAstTraitExpression extends CJAstTraitOrTypeExpression {
    CJAstTraitExpression(CJMark mark, String name, List<CJAstTypeExpression> args) {
        super(mark, name, args);
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitTrait(this, a);
    }
}
