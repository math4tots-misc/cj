package crossj.cj;

public final class CJAstParameter extends CJAstNode {
    private final String name;
    private final CJAstTypeExpression type;

    CJAstParameter(CJMark mark, String name, CJAstTypeExpression type) {
        super(mark);
        this.name = name;
        this.type = type;
    }

    public String getName() {
        return name;
    }

    public CJAstTypeExpression getType() {
        return type;
    }
}
