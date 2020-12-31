package crossj.cj;

/**
 * Pass 1
 *
 * Create type parameter ir for each item
 */
final class CJPass01 extends CJPassBase {
    CJPass01(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        var defn = item.getAst();
        for (var typeParameterAst : defn.getTypeParameters()) {
            var typeParameter = new CJIRTypeParameter(typeParameterAst);
            item.getTypeParameters().add(typeParameter);
            item.getTypeParameterMap().put(typeParameter.getName(), typeParameter);
        }
    }
}
