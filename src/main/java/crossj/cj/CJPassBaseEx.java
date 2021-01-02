package crossj.cj;

/**
 * Extends CJPassBase with some extra ops that are only available once pass02
 * has finished.
 */
public abstract class CJPassBaseEx extends CJPassBase {
    CJPassBaseEx(CJIRContext ctx) {
        super(ctx);
    }
}
