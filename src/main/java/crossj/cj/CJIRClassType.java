package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

public final class CJIRClassType extends CJIRTraitOrClassType implements CJIRType {
    private final CJIRItem item;
    private final List<CJIRType> args;

    CJIRClassType(CJIRItem item, List<CJIRType> args) {
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
    public CJIRMethodRef findMethodOrNull(String shortName) {
        return super.findMethodOrNull(shortName);
    }

    @Override
    public String toString() {
        return item.getFullName() + (args.isEmpty() ? "" : "[" + Str.join(",", args) + "]");
    }

    @Override
    public <R, A> R accept(CJIRTypeVisitor<R, A> visitor, A a) {
        return visitor.visitClass(this, a);
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJIRClassType)) {
            return false;
        }
        var other = (CJIRClassType) obj;
        return item == other.item && args.equals(other.args);
    }
}
