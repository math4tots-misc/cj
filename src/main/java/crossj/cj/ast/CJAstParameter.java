package crossj.cj.ast;

import crossj.base.Optional;
import crossj.cj.CJMark;

public final class CJAstParameter extends CJAstNode {
    private final boolean mutable;
    private final String name;
    private final CJAstTypeExpression type;
    private final Optional<CJAstExpression> defaultExpression;

    public CJAstParameter(CJMark mark, boolean mutable, String name, CJAstTypeExpression type) {
        this(mark, mutable, name, type, Optional.empty());
    }

    public CJAstParameter(CJMark mark, boolean mutable, String name, CJAstTypeExpression type,
            Optional<CJAstExpression> defaultExpression) {
        super(mark);
        this.mutable = mutable;
        this.name = name;
        this.type = type;
        this.defaultExpression = defaultExpression;
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

    public Optional<CJAstExpression> getDefaultExpression() {
        return defaultExpression;
    }
}
