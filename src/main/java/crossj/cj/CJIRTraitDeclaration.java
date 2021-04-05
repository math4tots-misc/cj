package crossj.cj;

import crossj.base.List;
import crossj.cj.ast.CJAstTraitDeclaration;
import crossj.cj.ir.meta.CJIRTrait;

/**
 * Indicates that the current item implements the given trait if the given type
 * conditions are satisfied.
 */
public final class CJIRTraitDeclaration extends CJIRNode<CJAstTraitDeclaration> {
    private final CJIRTrait trait;
    private final List<CJIRTypeCondition> conditions = List.of();

    CJIRTraitDeclaration(CJAstTraitDeclaration ast, CJIRTrait trait) {
        super(ast);
        this.trait = trait;
    }

    public CJIRTrait getTrait() {
        return trait;
    }

    public List<CJIRTypeCondition> getConditions() {
        return conditions;
    }
}
