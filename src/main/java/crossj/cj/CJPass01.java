package crossj.cj;

import crossj.cj.ir.CJIRItem;
import crossj.cj.ir.CJIRTypeParameter;

/**
 * Pass 1
 *
 * Create type parameter ir for each item
 */
class CJPass01 extends CJPassBase {
    CJPass01(CJContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        checkItemName(item);
        var defn = item.getAst();
        for (var typeParameterAst : defn.getTypeParameters()) {
            var typeParameter = new CJIRTypeParameter(typeParameterAst);
            item.getTypeParameters().add(typeParameter);
            item.getTypeParameterMap().put(typeParameter.getName(), typeParameter);
        }
    }

    private void checkItemName(CJIRItem item) {
        var shortName = item.getShortName();
        var fullName = item.getFullName();
        var exceptions = CJContext.specialTypeNameMap.getOrNull(shortName);
        if (exceptions != null && !exceptions.contains(fullName)) {
            throw CJError.of(shortName + " is a reserved name and cannot be used for this item", item.getMark());
        }
    }
}
