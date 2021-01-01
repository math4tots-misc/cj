package crossj.cj;

import crossj.base.List;

abstract class CJIRTraitOrClassType {
    private CJIRBinding bindings = null;

    public abstract CJIRItem getItem();
    public abstract List<CJIRType> getArgs();

    public CJIRBinding getBindings() {
        if (bindings == null) {
            bindings = getItem().getBinding(getArgs());
        }
        return bindings;
    }

    public List<CJIRTrait> getTraits(CJMark... marks) {
        // TODO: Filter out disqualified traits based on type
        return getItem().getTraitDeclarations().map(td -> td.getTrait().apply(getBindings(), marks));
    }
}
