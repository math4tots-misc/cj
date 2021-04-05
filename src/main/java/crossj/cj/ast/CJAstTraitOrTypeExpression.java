package crossj.cj.ast;

import crossj.base.List;
import crossj.cj.CJMark;

public abstract class CJAstTraitOrTypeExpression extends CJAstExpression {
    private final String name;
    private final List<CJAstTypeExpression> args;

    CJAstTraitOrTypeExpression(CJMark mark, String name, List<CJAstTypeExpression> args) {
        super(mark);
        this.name = name;
        this.args = args;
    }

    public String getName() {
        return name;
    }

    public List<CJAstTypeExpression> getArgs() {
        return args;
    }
}
