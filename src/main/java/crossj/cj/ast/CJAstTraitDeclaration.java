package crossj.cj.ast;

import crossj.base.List;
import crossj.cj.CJMark;

public final class CJAstTraitDeclaration extends CJAstNode {
    private final CJAstTraitExpression trait;
    private final List<CJAstTypeCondition> conditions;

    public CJAstTraitDeclaration(CJMark mark, CJAstTraitExpression trait, List<CJAstTypeCondition> conditions) {
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
