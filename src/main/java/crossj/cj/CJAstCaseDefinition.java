package crossj.cj;

import crossj.base.List;

public final class CJAstCaseDefinition extends CJAstItemMemberDefinition {
    private final List<CJAstTypeExpression> types;

    CJAstCaseDefinition(CJMark mark, List<CJIRModifier> modifiers, String name,
            List<CJAstTypeExpression> types) {
        super(mark, modifiers, name);
        this.types = types;
    }

    public List<CJAstTypeExpression> getTypes() {
        return types;
    }
}
