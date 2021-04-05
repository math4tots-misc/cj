package crossj.cj.ir.meta;

import crossj.base.List;
import crossj.cj.CJIRBinding;
import crossj.cj.CJIRItem;
import crossj.cj.CJIRMethodRef;

public abstract class CJIRTraitOrClassType {
    private CJIRBinding binding = null;
    private final CJIRItem item;
    private final List<CJIRType> args;

    CJIRTraitOrClassType(CJIRItem item, List<CJIRType> args) {
        this.item = item;
        this.args = args;
    }

    public final CJIRItem getItem() {
        return item;
    }

    public final List<CJIRType> getArgs() {
        return args;
    }

    public CJIRBinding getBinding() {
        if (binding == null) {
            binding = getItem().getBinding(getArgs());
        }
        return binding;
    }

    public CJIRBinding getBindingWithSelfType(CJIRType selfType) {
        return getItem().getBindingWithSelfType(selfType, getArgs());
    }

    public final String repr() {
        var sb = new StringBuilder();
        sb.append(getItem().getFullName());
        var args = getArgs();
        if (args.size() > 0) {
            sb.append("[");
            for (int i = 0; i < args.size(); i++) {
                if (i > 0) { sb.append(","); }
                sb.append(args.get(i).repr());
            }
            sb.append("]");
        }
        return sb.toString();
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
        throw new Error("Use CJIRType.toRawQualifiedName() instead");
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

    public final boolean isNative() {
        return getItem().isNative();
    }

    public String getImplicitMethodNameForTypeOrNull(CJIRType type) {
        if (type instanceof CJIRClassType) {
            var methodName = getItem().getImplicitsTypeItemMap().getOrNull(((CJIRClassType) type).getItem());
            if (methodName != null) {
                return methodName;
            }
        }
        for (var pair : getItem().getImplicitsTraitsList()) {
            var traitItem = pair.get1();
            if (type.getImplementingTraitByItemOrNull(traitItem) != null) {
                return pair.get2();
            }
        }
        return null;
    }

    @Override
    public int hashCode() {
        return List.of(getClass(), getItem(), getArgs()).hashCode();
    }

    @Override
    public boolean equals(Object obj) {
        if (!obj.getClass().equals(getClass())) {
            return false;
        }
        var other = (CJIRTraitOrClassType) obj;
        return getItem() == other.getItem() && getArgs().equals(other.getArgs());
    }
}
