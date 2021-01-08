package crossj.cj;

import crossj.base.List;

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
    public boolean isUnionType() {
        return item.getKind() == CJIRItemKind.Union;
    }

    @Override
    public boolean isListType() {
        return item.getFullName().equals("cj.List");
    }

    @Override
    public boolean isPromiseType() {
        return item.getFullName().equals("cj.Promise");
    }

    @Override
    public boolean isFunctionType() {
        switch (item.getFullName()) {
            case "cj.Fn0":
            case "cj.Fn1":
            case "cj.Fn2":
            case "cj.Fn3":
            case "cj.Fn4":
                return true;
        }
        return false;
    }

    @Override
    public CJIRMethodRef findMethodOrNull(String shortName) {
        return super.findMethodOrNull(shortName);
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
