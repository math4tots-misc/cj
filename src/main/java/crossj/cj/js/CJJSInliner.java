package crossj.cj.js;

import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.ir.CJIRJSBlob;
import crossj.cj.ir.CJIRLiteral;
import crossj.cj.ir.CJIRMethodCall;
import crossj.cj.ir.CJIRVariableAccess;
import crossj.cj.ir.meta.CJIRClassType;

final class CJJSInliner {

    private final CJJSExpressionTranslator expressionTranslator;

    public CJJSInliner(CJJSExpressionTranslator expressionTranslator) {
        this.expressionTranslator = expressionTranslator;
    }

    /**
     * Tries to inline a method call.
     *
     * A method can be inlined in a few cases:
     *
     *   - if the method has no parameters and returns a literal value
     *   - if the body of the method consists of a single
     *     CJIRJSBlob expression where every parameter of the method appears exactly
     *     once in the order they are declared.
     */
    public Optional<CJJSBlob> tryInline(CJIRMethodCall methodCall) {
        var method = methodCall.getMethodRef().getMethod();
        var args = methodCall.getArgs();
        var params = method.getParameters();
        if (method.getBody().isEmpty()) {
            return Optional.empty();
        }
        if (args.size() != params.size()) {
            return Optional.empty();
        }
        if (!(methodCall.getOwner() instanceof CJIRClassType)) {
            return Optional.empty();
        }
        if (params.size() == 0 && method.getBody().get() instanceof CJIRLiteral) {
            return Optional.of(expressionTranslator.translateExpression(method.getBody().get()));
        }
        if (!(method.getBody().get() instanceof CJIRJSBlob)) {
            return Optional.empty();
        }
        var blob = (CJIRJSBlob) method.getBody().get();
        var newParts = List.<Object>of();
        int argIndex = 0;
        var parts = blob.getParts();
        for (int i = 0; i < parts.size(); i++) {
            if (parts.get(i) instanceof String) {
                newParts.add(parts.get(i));
                continue;
            } else if (!(parts.get(i) instanceof CJIRVariableAccess)) {
                return Optional.empty();
            }
            if (argIndex >= params.size()) {
                return Optional.empty();
            }
            var param = params.get(argIndex);
            var arg = args.get(argIndex++);
            var decl = ((CJIRVariableAccess) parts.get(i)).getDeclaration();
            if (param != decl) {
                return Optional.empty();
            }
            newParts.add(arg);
        }
        if (argIndex != params.size()) {
            return Optional.empty();
        }
        var newBlob = new CJIRJSBlob(methodCall.getAst(), methodCall.getType(), newParts);
        return Optional.of(expressionTranslator.translateBlob(newBlob));
    }
}
