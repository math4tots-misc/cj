package crossj.cj;

import crossj.base.Optional;

public final class CJIRLocalContext {
    private final CJIRContext global;
    private final CJIRItem item;
    private final Optional<CJIRMethod> method;

    CJIRLocalContext(CJIRContext global, CJIRItem item, Optional<CJIRMethod> method) {
        this.global = global;
        this.item = item;
        this.method = method;
    }

    public CJIRItem getItem() {
        return item;
    }

    CJIRItem getTraitItem(String shortName, CJMark... marks) {
        var fullName = item.getShortNameMap().getOrNull(shortName);
        if (fullName == null) {
            throw CJError.of("Trait " + shortName + " not found", marks);
        }
        var item = global.loadItem(fullName, marks);
        if (!item.getKind().isTraitKind()) {
            throw CJError.of(fullName + " is not a trait item", marks);
        }
        return item;
    }

    CJIRItem getTypeItem(String shortName, CJMark... marks) {
        var fullName = item.getShortNameMap().getOrNull(shortName);
        if (fullName == null) {
            throw CJError.of("Type " + shortName + " not found", marks);
        }
        var item = global.loadItem(fullName, marks);
        if (!item.getKind().isTypeKind()) {
            throw CJError.of(fullName + " is not a type item (i.e. class or union)", marks);
        }
        return item;
    }
}
