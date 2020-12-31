package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

public final class CJIRClassType extends CJIRType {
    private final CJIRItem item;
    private final List<CJIRType> args;

    CJIRClassType(CJIRItem item, List<CJIRType> args) {
        this.item = item;
        this.args = args;
    }

    public CJIRItem getItem() {
        return item;
    }

    public List<CJIRType> getArgs() {
        return args;
    }

    @Override
    public String toString() {
        return item.getFullName() + "[" + Str.join(",", getArgs()) + "]";
    }
}
