package crossj.cj;

import crossj.base.List;
import crossj.base.Tuple3;

public final class CJAstLambda extends CJAstExpression {
    private final List<Tuple3<CJMark, Boolean, String>> parameters;
    private final CJAstExpression body;

    CJAstLambda(CJMark mark, List<Tuple3<CJMark, Boolean, String>> parameters, CJAstExpression body) {
        super(mark);
        this.parameters = parameters;
        this.body = body;
    }

    public List<Tuple3<CJMark, Boolean, String>> getParameters() {
        return parameters;
    }

    public CJAstExpression getBody() {
        return body;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLambda(this, a);
    }
}
