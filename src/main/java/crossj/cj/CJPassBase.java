package crossj.cj;

import crossj.base.Optional;

abstract class CJPassBase {
    protected final CJIRContext ctx;
    protected CJIRLocalContext lctx = null;

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
}
