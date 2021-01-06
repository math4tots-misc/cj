package crossj.cj;

import crossj.base.List;

public final class CJAstAnnotationExpression extends CJAstNode {
    public final String name;
    public final List<CJAstAnnotationExpression> args;

    CJAstAnnotationExpression(CJMark mark, String name, List<CJAstAnnotationExpression> args) {
        super(mark);
        this.name = name;
        this.args = args;
    }

    public String getName() {
        return name;
    }

    public List<CJAstAnnotationExpression> getArgs() {
        return args;
    }
}
