package crossj.cj.ast;

import crossj.cj.CJMark;

public final class CJAstParameter extends CJAstNode {
    private final boolean mutable;
    private final String name;
    private final CJAstTypeExpression type;

    public CJAstParameter(CJMark mark, boolean mutable, String name, CJAstTypeExpression type) {
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
