package crossj.cj;

import crossj.base.List;

public final class CJIRTypeCondition extends CJIRNode<CJAstTypeCondition> {
    private final CJIRTypeParameter typeParameter;
    private final List<CJIRTrait> traits = List.of();

    CJIRTypeCondition(CJAstTypeCondition ast, CJIRTypeParameter typeParameter) {
        super(ast);
        this.typeParameter = typeParameter;
    }

    public CJIRTypeParameter getTypeParameter() {
        return typeParameter;
    }

    public List<CJIRTrait> getTraits() {
        return traits;
    }
}
