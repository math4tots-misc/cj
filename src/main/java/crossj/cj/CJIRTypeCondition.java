package crossj.cj;

import crossj.base.List;

public final class CJIRTypeCondition extends CJIRNode<CJAstTypeCondition> {
    private final CJIRTypeParameter variableDeclaration;
    private final List<CJIRTrait> traits = List.of();

    CJIRTypeCondition(CJAstTypeCondition ast, CJIRTypeParameter variableDeclaration) {
        super(ast);
        this.variableDeclaration = variableDeclaration;
    }

    public CJIRTypeParameter getVariableDeclaration() {
        return variableDeclaration;
    }

    public List<CJIRTrait> getTraits() {
        return traits;
    }
}
