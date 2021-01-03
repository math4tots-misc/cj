package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

abstract class CJIRTraitOrClassType {
    private CJIRBinding bindings = null;

    public abstract CJIRItem getItem();
    public abstract List<CJIRType> getArgs();

    public CJIRBinding getBinding() {
        if (bindings == null) {
            bindings = getItem().getBinding(getArgs());
        }
        return bindings;
    }

    public List<CJIRTrait> getTraits(CJMark... marks) {
        // TODO: Filter out disqualified traits based on type
        return getItem().getTraitDeclarations().map(td -> td.getTrait().apply(getBinding(), marks));
    }

    public CJIRMethodRef findMethodOrNull(String shortName) {
        var method = getItem().getMethodOrNull(shortName);
        if (method != null) {
            return new CJIRMethodRef(this, method);
        }
        for (var trait : getTraits()) {
            var methodRef = trait.findMethodOrNull(shortName);
            if (methodRef != null) {
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
        for (var member : getItem().getMembers()) {
            if (member instanceof CJIRMethod) {
                var method = (CJIRMethod) member;
                ret.add(new CJIRMethodRef(this, method));
            }
        }
        return ret;
    }
}
