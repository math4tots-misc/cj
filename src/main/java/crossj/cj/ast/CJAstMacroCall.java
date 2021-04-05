package crossj.cj.ast;

import crossj.base.List;
import crossj.cj.CJMark;

public final class CJAstMacroCall extends CJAstExpression {
    private final String name;
    private final List<CJAstExpression> args;

    public CJAstMacroCall(CJMark mark, String name, List<CJAstExpression> args) {
        super(mark);
        this.name = name;
        this.args = args;
    }

    public String getName() {
        return name;
    }

    public List<CJAstExpression> getArgs() {
        return args;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitMacroCall(this, a);
    }
}
