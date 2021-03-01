package crossj.cj;

/**
 * Javascript Translation Context
 */
public final class CJJSContext {
    private int nextTempVarId = 0;

    void resetVarIds() {
        nextTempVarId = 0;
    }

    String newTempVarName() {
        return "L$" + nextTempVarId++;
    }
}
