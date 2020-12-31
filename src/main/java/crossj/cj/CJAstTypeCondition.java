package crossj.cj;

import crossj.base.List;

public final class CJAstTypeCondition extends CJAstNode {
    private final String variableName;
    private final List<CJAstTraitExpression> traits;

    CJAstTypeCondition(CJMark mark, String variableName, List<CJAstTraitExpression> traits) {
        super(mark);
        this.variableName = variableName;
        this.traits = traits;
    }

    public String getVariableName() {
        return variableName;
    }

    public List<CJAstTraitExpression> getTraits() {
        return traits;
    }
}
