package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

public final class CJIRTrait extends CJIRTraitOrClassType {
    private final CJIRItem item;
    private final List<CJIRType> args;
    private CJIRBinding binding;

    CJIRTrait(CJIRItem item, List<CJIRType> args) {
        this.item = item;
        this.args = args;
    }

    @Override
    public CJIRItem getItem() {
        return item;
    }

    public List<CJIRType> getArgs() {
        return args;
    }

    @Override
    public CJIRBinding getBindings() {
        if (binding == null) {
            binding = item.getBinding(args);
        }
        return binding;
    }

    @Override
    public String toString() {
        return item.getFullName() + "[" + Str.join(",", getArgs()) + "]";
    }

    public CJIRTrait apply(CJIRBinding binding, CJMark... marks) {
        return new CJIRTrait(item, args.map(arg -> binding.apply(arg, marks)));
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJIRTrait)) {
            return false;
        }
        var other = (CJIRTrait) obj;
        return item == other.item && args.equals(other.args);
    }
}
