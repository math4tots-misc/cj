package crossj.cj.ast;

import crossj.base.List;
import crossj.cj.CJMark;

public final class CJAstAnnotationExpression extends CJAstNode {
    public final String name;
    public final List<CJAstAnnotationExpression> args;

    public CJAstAnnotationExpression(CJMark mark, String name, List<CJAstAnnotationExpression> args) {
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
