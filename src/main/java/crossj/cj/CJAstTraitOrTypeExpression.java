package crossj.cj;

import crossj.base.List;

abstract class CJAstTraitOrTypeExpression extends CJAstExpression {
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
