package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

abstract class CJIRTraitOrClassType {
    private CJIRBinding binding = null;

    public abstract CJIRItem getItem();
    public abstract List<CJIRType> getArgs();

    private CJIRBinding getBinding() {
        if (binding == null) {
            binding = getItem().getBinding(getArgs());
        }
        return binding;
    }

    public CJIRBinding getBindingWithSelfType(CJIRType selfType) {
        return getItem().getBindingWithSelfType(selfType, getArgs());
    }

    public List<CJIRTrait> getTraits() {
        // TODO: Filter out disqualified traits based on type
        return getItem().getTraitDeclarations().map(td -> td.getTrait().apply(getBinding()));
    }

    public CJIRMethodRef findMethodOrNull(String shortName) {
        var method = getItem().getMethodOrNull(shortName);
        if (method != null) {
            return new CJIRMethodRef(this, method);
        }
        for (var trait : getTraits()) {
            var methodRef = trait.findMethodOrNull(shortName);
            if (methodRef != null) {
                // TODO: Filter out methods that don't have all its conditions satisfied.
                return methodRef;
            }
        }
        return null;
    }

    @Override
    public final String toString() {
        return getItem().getFullName() + (getArgs().isEmpty() ? "" : "[" + Str.join(",", getArgs()) + "]");
    }

    public final List<CJIRMethodRef> getMethodRefs() {
        var ret = List.<CJIRMethodRef>of();
        for (var method : getItem().getMethods()) {
            ret.add(new CJIRMethodRef(this, method));
        }
        return ret;
    }

    public final boolean isTrait() {
        return getItem().isTrait();
    }
}
