package crossj.cj;

import crossj.base.Assert;
import crossj.base.Func1;
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

    void walkTraits(CJIRItem item, Func1<Void, CJIRTrait> f) {
        CJIRContextBase.walkTraits(item, f);
    }

    List<CJAstTraitExpression> synthesizeTypeVariableAutoTraits(CJAstTypeParameter ast) {
        var annotationProcessor = CJIRAnnotationProcessor.processTypeParameter(ast);
        if (annotationProcessor.isNullable()) {
            return List.of();
        } else {
            return List.of(new CJAstTraitExpression(ast.getMark(), "NonNull", List.of()));
        }
    }
}
