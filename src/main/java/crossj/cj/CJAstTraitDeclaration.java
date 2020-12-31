package crossj.cj;

import crossj.base.List;

public final class CJAstTraitDeclaration extends CJAstNode {
    private final CJAstTraitExpression trait;
    private final List<CJAstTypeCondition> conditions;

    CJAstTraitDeclaration(CJMark mark, CJAstTraitExpression trait, List<CJAstTypeCondition> conditions) {
        super(mark);
        this.trait = trait;
        this.conditions = conditions;
    }

    public CJAstTraitExpression getTrait() {
        return trait;
    }

    public List<CJAstTypeCondition> getConditions() {
        return conditions;
    }
}
