package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;

abstract class CJPassBase {
    protected final CJIRContext ctx;
    protected CJIRLocalContext lctx = null;
    private CJIRLocalContext lctxPushed = null;

    CJPassBase(CJIRContext ctx) {
        this.ctx = ctx;
    }

    void run() {
        for (var item : ctx.getAllLoadedItems()) {
            lctx = new CJIRLocalContext(ctx, item, Optional.empty());
            handleItem(item);
        }
    }

    void handleItem(CJIRItem item) {
    }

    void enterMethod(CJIRMethod method) {
        Assert.equals(lctxPushed, null);
        lctxPushed = lctx;
        lctx = new CJIRLocalContext(lctxPushed.getGlobal(), lctxPushed.getItem(), Optional.of(method));
    }

    void exitMethod() {
        Assert.that(lctxPushed != null);
        lctx = lctxPushed;
        lctxPushed = null;
    }

    List<CJAstTraitExpression> synthesizeTypeVariableAutoTraits(CJIRTypeParameter typeParameter) {
        var annotationProcessor = typeParameter.getAnnotation();
        var list = List.<CJAstTraitExpression>of();
        if (!annotationProcessor.isNullable()) {
            list.add(new CJAstTraitExpression(typeParameter.getMark(), "NonNull", List.of()));
        }
        list.add(new CJAstTraitExpression(typeParameter.getMark(), "Any", List.of()));
        return list;
    }
}
