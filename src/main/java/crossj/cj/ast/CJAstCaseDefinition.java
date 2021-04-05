package crossj.cj.ast;

import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJMark;
import crossj.cj.ir.CJIRModifier;

public final class CJAstCaseDefinition extends CJAstItemMemberDefinition {
    private final List<CJAstTypeExpression> types;

    public CJAstCaseDefinition(CJMark mark, Optional<String> comment, List<CJAstAnnotationExpression> annotations, List<CJIRModifier> modifiers, String name,
            List<CJAstTypeExpression> types) {
        super(mark, comment, annotations, modifiers, name);
        this.types = types;
    }

    public List<CJAstTypeExpression> getTypes() {
        return types;
    }
}
