package crossj.cj.ir.meta;

import crossj.base.List;
import crossj.cj.CJMark;
import crossj.cj.ir.CJIRBinding;
import crossj.cj.ir.CJIRItem;

public final class CJIRTrait extends CJIRTraitOrClassType {
    public CJIRTrait(CJIRItem item, List<CJIRType> args) {
        super(item, args);
    }

    public CJIRTrait apply(CJIRBinding binding, CJMark... marks) {
        return new CJIRTrait(getItem(), getArgs().map(arg -> binding.apply(arg, marks)));
    }

    CJIRTrait getImplementingTraitByItemOrNull(CJIRItem item) {
        if (getItem() == item) {
            return this;
        }
        for (var subtrait : getTraits()) {
            var ret = subtrait.getImplementingTraitByItemOrNull(item);
            if (ret != null) {
                return ret;
            }
        }
        return null;
    }

    boolean extendsTrait(CJIRTrait trait) {
        if (this.equals(trait)) {
            return true;
        }
        for (var subtrait : this.getTraits()) {
            if (subtrait.extendsTrait(trait)) {
                return true;
            }
        }
        return false;
    }
}
