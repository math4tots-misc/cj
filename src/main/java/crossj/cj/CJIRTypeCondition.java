package crossj.cj;

import crossj.base.List;
import crossj.cj.ast.CJAstTypeCondition;
import crossj.cj.ir.meta.CJIRTrait;

public final class CJIRTypeCondition extends CJIRNode<CJAstTypeCondition> {
    private final CJIRTypeParameter typeParameter;
    private final List<CJIRTrait> traits = List.of();

    public CJIRTypeCondition(CJAstTypeCondition ast, CJIRTypeParameter typeParameter) {
        super(ast);
        this.typeParameter = typeParameter;
    }

    public CJIRTypeParameter getTypeParameter() {
        return typeParameter;
    }

    public List<CJIRTrait> getTraits() {
        return traits;
    }

    /**
     * Test whether the given binding satisfies this type condition.
     *
     * NOTE: The binding should be a binding for the item in which this type
     * condition is declared.
     *
     * NOTE2: conditions should always only need to look at the bindings of the
     * item. In particular, type conditions on methods should not refer to any type
     * varaibles on the methods itself, since the conditions are meant to determine
     * whether the method should even "exist" at all.
     */
    public boolean isSatisfied(CJIRBinding binding) {
        var boundType = binding.get(typeParameter.getName());
        for (var trait : traits.map(t -> t.apply(binding))) {
            if (!boundType.implementsTrait(trait)) {
                return false;
            }
        }
        return true;
    }
}
