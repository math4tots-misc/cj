package crossj.cj.ast;

import crossj.base.List;
import crossj.cj.CJMark;

public final class CJAstTraitExpression extends CJAstTraitOrTypeExpression {
    public CJAstTraitExpression(CJMark mark, String name, List<CJAstTypeExpression> args) {
        super(mark, name, args);
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitTrait(this, a);
    }
}
