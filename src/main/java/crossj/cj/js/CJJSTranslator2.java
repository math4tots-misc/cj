package crossj.cj.js;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Pair;
import crossj.base.Set;
import crossj.cj.CJError;
import crossj.cj.CJIRContext;
import crossj.cj.CJIRField;
import crossj.cj.CJIRRunMode;
import crossj.cj.CJIRRunModeMain;
import crossj.cj.CJIRRunModeTest;
import crossj.cj.CJIRRunModeVisitor;
import crossj.cj.CJIRRunModeWWW;
import crossj.cj.CJJSSink;
import crossj.cj.CJMark;

public final class CJJSTranslator2 {
    public static CJJSSink translate(CJIRContext irctx, CJIRRunMode runMode) {
        var tr = new CJJSTranslator2(irctx);
        runMode.accept(new CJIRRunModeVisitor<Void, Void>() {

            @Override
            public Void visitMain(CJIRRunModeMain m, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public Void visitTest(CJIRRunModeTest m, Void a) {
                var items = irctx.getAllLoadedItems();
                for (var item : items) {
                    var testMethods = item.getMethods().filter(meth -> meth.isTest());
                    if (testMethods.isEmpty()) {
                        continue;
                    }
                    for (var method : testMethods) {
                        tr.queueMethodByName(item.getFullName(), method.getName());
                    }
                }
                return null;
            }

            @Override
            public Void visitWWW(CJIRRunModeWWW m, Void a) {
                // TODO Auto-generated method stub
                return null;
            }
        }, null);
        tr.emitQueued();
        runMode.accept(new CJIRRunModeVisitor<Void, Void>() {
            @Override
            public Void visitMain(CJIRRunModeMain m, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public Void visitTest(CJIRRunModeTest m, Void a) {
                var out = tr.out;
                var items = irctx.getAllLoadedItems();
                int testCount = 0;
                int itemCount = 0;
                out.addMark(CJMark.of("<test>", 1, 1));
                for (var item : items) {
                    var testMethods = item.getMethods().filter(meth -> meth.isTest());
                    if (testMethods.isEmpty()) {
                        continue;
                    }
                    itemCount++;
                    for (var method : testMethods) {
                        testCount++;
                        out.append("console.log('    testing " + method.getName() + "');\n");
                        var jsMethodName = tr.methodNameRegistry.getName(item.getFullName(), method.getName(),
                                CJJSTypeBinding.empty());
                        out.append(jsMethodName + "();\n");
                    }
                }
                out.append("console.log('" + testCount + " tests in " + itemCount + " items pass');\n");
                return null;
            }

            @Override
            public Void visitWWW(CJIRRunModeWWW m, Void a) {
                // TODO Auto-generated method stub
                return null;
            }
        }, null);
        return tr.out;
    }

    private final CJIRContext ctx;
    private final CJJSSink out = new CJJSSink();
    private final CJJSMethodNameRegistry methodNameRegistry = new CJJSMethodNameRegistry();
    private final CJJSTempVarFactory varFactory = new CJJSTempVarFactory();
    private final List<CJJSReifiedMethod> todoMethods = List.of();
    private final Set<String> queuedMethods = Set.of();
    private final List<Pair<CJJSReifiedType, CJIRField>> todoStaticFields = List.of();
    private final Set<String> queuedStaticFields = Set.of();

    public CJJSTranslator2(CJIRContext ctx) {
        this.ctx = ctx;
    }

    public void queueMethod(CJJSReifiedMethod reifiedMethod) {
        var id = reifiedMethod.getId();
        if (!queuedMethods.contains(id)) {
            queuedMethods.add(id);
            todoMethods.add(reifiedMethod);
        }
    }

    public void queueStaticField(CJJSReifiedType owner, CJIRField field) {
        var id = owner.getItem().getFullName() + "." + field.getName();
        if (!queuedStaticFields.contains(id)) {
            queuedStaticFields.add(id);
            todoStaticFields.add(Pair.of(owner, field));
        }
    }

    public void queueMethodByName(String itemName, String methodName) {
        var item = ctx.loadItem(itemName);
        var method = item.getMethodOrNull(methodName);
        Assert.that(method != null);
        if (item.getTypeParameters().size() > 0 || method.getTypeParameters().size() > 0) {
            throw CJError.of("queueMethodByName cannot process generic items or methods");
        }
        var owner = new CJJSReifiedType(item, List.of());
        queueMethod(new CJJSReifiedMethod(owner, method, CJJSTypeBinding.empty()));
    }

    public void emitQueued() {
        while (todoMethods.size() > 0) {
            var reifiedMethod = todoMethods.pop();
            emitMethod(reifiedMethod);
        }
        while (todoStaticFields.size() > 0) {
            var pair = todoStaticFields.pop();
            emitStaticField(pair.get1(), pair.get2());
        }
    }

    private void emitMethod(CJJSReifiedMethod reifiedMethod) {
        var method = reifiedMethod.getMethod();
        if (method.getBody().isEmpty()) {
            return;
        }
        var owner = reifiedMethod.getOwner();
        var binding = reifiedMethod.getBinding();
        var methodName = methodNameRegistry.getName(owner.getItem().getFullName(), method.getName(), binding);
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
        blob.emitSet(out, "return ");
        out.append("}\n");
    }

    private void emitStaticField(CJJSReifiedType owner, CJIRField field) {
    }
}
