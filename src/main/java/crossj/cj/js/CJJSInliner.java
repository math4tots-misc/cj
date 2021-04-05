package crossj.cj.js;

import crossj.base.Optional;
import crossj.cj.ir.CJIRJSBlob;
import crossj.cj.ir.CJIRMethod;
import crossj.cj.ir.CJIRVariableAccess;

public final class CJJSInliner {

    /**
     * Tests whether this method can be inlined.
     *
     * A method can be inlined if the body of the method consists of a single
     * CJIRJSBlob expression where every parameter of the method appears exactly
     * once in the order they are declared.
     */
    public static boolean canInline(CJIRMethod method) {
        if (method.getBody().isEmpty()) {
            return false;
        }
        if (!(method.getBody().get() instanceof CJIRJSBlob)) {
            return false;
        }
        var blob = (CJIRJSBlob) method.getBody().get();
        var params = method.getParameters();
        int paramIndex = 0;
        var parts = blob.getParts();
        for (int i = 0; i < parts.size(); i++) {
            if (parts.get(i) instanceof String) {
                continue;
            } else if (!(parts.get(i) instanceof CJIRVariableAccess)) {
                return false;
            }
            if (paramIndex > params.size()) {
                return false;
            }
            var param = params.get(paramIndex++);
            var decl = ((CJIRVariableAccess) parts.get(i)).getDeclaration();
        }
        return paramIndex == params.size();
    }
}
