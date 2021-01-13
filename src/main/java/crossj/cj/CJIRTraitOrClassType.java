package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

abstract class CJIRTraitOrClassType {
    private CJIRBinding binding = null;

    public abstract CJIRItem getItem();
    public abstract List<CJIRType> getArgs();

    CJIRBinding getBinding() {
        if (binding == null) {
            binding = getItem().getBinding(getArgs());
        }
        return binding;
    }

    public CJIRBinding getBindingWithSelfType(CJIRType selfType) {
        return getItem().getBindingWithSelfType(selfType, getArgs());
    }

    public List<CJIRTrait> getTraits() {
        var traits = List.<CJIRTrait>of();
        var binding = getBinding();
        for (var decl : getItem().getTraitDeclarations()) {
            if (decl.getConditions().all(cond -> cond.isSatisfied(binding))) {
                traits.add(decl.getTrait().apply(binding));
            }
        }
        return traits;
    }

    public CJIRMethodRef findMethodOrNull(String shortName) {
        var method = getItem().getMethodOrNull(shortName);
        if (method != null) {
            var methodRef = new CJIRMethodRef(this, method);
            return methodRef.satisfiesAllConditions() ? methodRef : null;
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
        var args = getArgs().map(arg -> getBinding().tryApply(arg));
        return getItem().getFullName() + (args.isEmpty() ? "" : "[" + Str.join(",", args) + "]");
    }

    public final List<CJIRMethodRef> getMethodRefs() {
        return getMethodRefsRegardlessOfConditions().filter(m -> m.satisfiesAllConditions());
    }

    public final List<CJIRMethodRef> getMethodRefsRegardlessOfConditions() {
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
