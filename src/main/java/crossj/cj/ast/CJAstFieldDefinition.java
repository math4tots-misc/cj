package crossj.cj.ast;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJIRModifier;
import crossj.cj.CJMark;

public final class CJAstFieldDefinition extends CJAstItemMemberDefinition {
    private final boolean mutable;
    private final CJAstTypeExpression type;
    private final Optional<CJAstExpression> expression;

    public CJAstFieldDefinition(CJMark mark, Optional<String> comment, List<CJAstAnnotationExpression> annotations, List<CJIRModifier> modifiers, boolean mutable, String name, CJAstTypeExpression type,
            Optional<CJAstExpression> expression) {
        super(mark, comment, annotations, modifiers, name);
        this.mutable = mutable;
        this.type = type;
        this.expression = expression;
    }

    public boolean isMutable() {
        return mutable;
    }

    public CJAstTypeExpression getType() {
        return type;
    }

    public Optional<CJAstExpression> getExpression() {
        return expression;
    }

    public String getGetterName() {
        return "__get_" + getName();
    }

    public String getSetterName() {
        Assert.that(mutable);
        return "__set_" + getName();
    }
}
