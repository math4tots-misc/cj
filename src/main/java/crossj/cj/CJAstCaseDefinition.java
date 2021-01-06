package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;

public final class CJAstCaseDefinition extends CJAstItemMemberDefinition {
    private final List<CJAstTypeExpression> types;

    CJAstCaseDefinition(CJMark mark, Optional<String> comment, List<CJAstAnnotationExpression> annotations, List<CJIRModifier> modifiers, String name,
            List<CJAstTypeExpression> types) {
        super(mark, comment, annotations, modifiers, name);
        this.types = types;
    }

    public List<CJAstTypeExpression> getTypes() {
        return types;
    }
}
