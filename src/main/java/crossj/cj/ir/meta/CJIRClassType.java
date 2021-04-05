package crossj.cj.ir.meta;

import crossj.base.List;
import crossj.cj.CJIRItem;
import crossj.cj.CJIRItemKind;
import crossj.cj.CJIRMethodRef;
import crossj.cj.CJIRTypeVisitor;

public final class CJIRClassType extends CJIRTraitOrClassType implements CJIRType {
    public CJIRClassType(CJIRItem item, List<CJIRType> args) {
        super(item, args);
    }

    @Override
    public boolean isUnionType() {
        return getItem().getKind() == CJIRItemKind.Union;
    }

    @Override
    public boolean isListType() {
        return getItem().getFullName().equals("cj.List");
    }

    @Override
    public boolean isTupleType() {
        return getItem().getFullName().startsWith("cj.Tuple");
    }

    @Override
    public boolean isNullableType() {
        return getItem().getFullName().equals("cj.Nullable");
    }

    @Override
    public boolean isUnitType() {
        return getItem().getFullName().equals("cj.Unit");
    }

    @Override
    public boolean isNoReturnType() {
        return getItem().getFullName().equals("cj.NoReturn");
    }

    @Override
    public boolean isPromiseType() {
        return getItem().getFullName().equals("cj.Promise");
    }

    @Override
    public boolean isAbsoluteType() {
        return getArgs().all(a -> a.isAbsoluteType());
    }

    @Override
    public boolean isFunctionType() {
        switch (getItem().getFullName()) {
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
    public String toRawQualifiedName() {
        return getItem().getFullName();
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
    public boolean isSimpleUnion() {
        return getItem().isSimpleUnion();
    }
}
