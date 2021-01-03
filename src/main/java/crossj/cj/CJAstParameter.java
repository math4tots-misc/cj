package crossj.cj;

public final class CJAstParameter extends CJAstNode {
    private final boolean mutable;
    private final String name;
    private final CJAstTypeExpression type;

    CJAstParameter(CJMark mark, boolean mutable, String name, CJAstTypeExpression type) {
        super(mark);
        this.mutable = mutable;
        this.name = name;
        this.type = type;
    }

    public boolean isMutable() {
        return mutable;
    }

    public String getName() {
        return name;
    }

    public CJAstTypeExpression getType() {
        return type;
    }
}
