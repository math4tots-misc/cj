package crossj.cj.ast;

import crossj.base.List;
import crossj.cj.CJMark;

public final class CJAstTypeExpression extends CJAstTraitOrTypeExpression {
    public CJAstTypeExpression(CJMark mark, String name, List<CJAstTypeExpression> args) {
        super(mark, name, args);
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitType(this, a);
    }
}
