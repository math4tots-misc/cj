package crossj.cj.js;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Set;
import crossj.base.Tuple3;
import crossj.cj.CJError;
import crossj.cj.CJIRContext;
import crossj.cj.CJIRItem;
import crossj.cj.CJIRMethod;
import crossj.cj.CJJSSink;

public final class CJJSTranslator2 {
    private final CJIRContext ctx;
    private final CJJSSink out = new CJJSSink();
    private final CJJSMethodNameRegistry methodNameRegistry = new CJJSMethodNameRegistry();
    private final CJJSTempVarFactory varFactory = new CJJSTempVarFactory();
    private final List<Tuple3<CJIRItem, CJIRMethod, CJJSTypeBinding>> todo = List.of();
    private final Set<String> queued = Set.of();

    public CJJSTranslator2(CJIRContext ctx) {
        this.ctx = ctx;
    }

    public void queueMethodByName(String itemName, String methodName) {
        var item = ctx.loadItem(itemName);
        var method = item.getMethodOrNull(methodName);
        Assert.that(method != null);
        if (item.getTypeParameters().size() > 0 || method.getTypeParameters().size() > 0) {
            throw CJError.of("queueMethodByName cannot be used with generic items or methods (" + itemName + "."
                    + methodName + ")", method.getMark());
        }
        queueMethod(item, method, CJJSTypeBinding.empty());
    }

    private void queueMethod(CJIRItem item, CJIRMethod method, CJJSTypeBinding binding) {
        var methodName = methodNameRegistry.getName(item.getFullName(), method.getName(), binding);
        if (!queued.contains(methodName)) {
            queued.add(methodName);
            todo.add(Tuple3.of(item, method, binding));
        }
    }

    public void emitQueued() {
        while (todo.size() > 0) {
            var triple = todo.pop();
            emitMethod(triple.get1(), triple.get2(), triple.get3());
        }
    }

    private void emitMethod(CJIRItem item, CJIRMethod method, CJJSTypeBinding binding) {
        if (method.getBody().isEmpty()) {
            return;
        }
        var methodName = methodNameRegistry.getName(item.getFullName(), method.getName(), binding);
        out.append("function ");
        out.addMark(method.getMark());
        out.append(methodName);
        out.append("(");
        for (int i = 0; i < method.getParameters().size(); i++) {
            if (i > 0) {
                out.append(",");
            }
            out.append("L$" + method.getParameters().get(i).getName());
        }
        out.append("){");
        var expressionTranslator = new CJJSExpressionTranslator2(varFactory, binding);
        var blob = expressionTranslator.translate(method.getBody().get());
        blob.emitPrep(out);
        out.append("return ");
        blob.emitBody(out);
        out.append("}\n");
    }
}
