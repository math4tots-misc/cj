package crossj.cj;

import crossj.base.List;

public final class CJIRTypeCondition extends CJIRNode<CJAstTypeCondition> {
    private final CJIRVariableType variable;
    private final List<CJIRTrait> traits = List.of();

    CJIRTypeCondition(CJAstTypeCondition ast, CJIRVariableType variable) {
        super(ast);
        this.variable = variable;
    }

    public CJIRVariableType getVariable() {
        return variable;
    }

    public List<CJIRTrait> getTraits() {
        return traits;
    }
}
