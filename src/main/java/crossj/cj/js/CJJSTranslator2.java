package crossj.cj.js;

import crossj.base.Assert;
import crossj.base.Deque;
import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Pair;
import crossj.base.Set;
import crossj.cj.CJError;
import crossj.cj.CJIRContext;
import crossj.cj.CJIRExpression;
import crossj.cj.CJIRField;
import crossj.cj.CJIRFieldMethodInfo;
import crossj.cj.CJIRLiteral;
import crossj.cj.CJIRNullWrap;
import crossj.cj.CJIRRunMode;
import crossj.cj.CJIRRunModeMain;
import crossj.cj.CJIRRunModeTest;
import crossj.cj.CJIRRunModeVisitor;
import crossj.cj.CJIRRunModeWWW;
import crossj.cj.CJJSSink;
import crossj.cj.CJMark;
import crossj.cj.CJToken;

public final class CJJSTranslator2 {
    private static final String jsroot = FS.join("src", "main", "resources", "js2");

    private static final Map<String, Set<String>> nativeDepMap = Map.of(
            Pair.of("cj.DynamicBuffer.addUTF8.js",
                    Set.of("cj.DynamicBuffer.fromUTF8.js", "cj.DynamicBuffer.addBuffer.js")),
            Pair.of("cj.DynamicBuffer.fromUTF8.js", Set.of("cj.DynamicBuffer.fromArrayBuffer.js")),
            Pair.of("cj.DynamicBuffer.ofU8s.js", Set.of("cj.DynamicBuffer.fromArrayBuffer.js")));

    public static CJJSSink translate(CJIRContext irctx, CJIRRunMode runMode) {
        var tr = new CJJSTranslator2(irctx);
        runMode.accept(new CJIRRunModeVisitor<Void, Void>() {

            @Override
            public Void visitMain(CJIRRunModeMain m, Void a) {
                tr.queueMethodByName(m.getMainClass(), "main");
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
        tr.out.append("(function(){\n\"use strict\";\n");
        tr.emitQueued();
        runMode.accept(new CJIRRunModeVisitor<Void, Void>() {
            @Override
            public Void visitMain(CJIRRunModeMain m, Void a) {
                var mainMethodName = tr.methodNameRegistry.getNonGenericName(m.getMainClass(), "main");
                tr.out.append(mainMethodName + "();\n");
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
                    out.append("console.log('in " + item.getFullName() + "');\n");
                    itemCount++;
                    for (var method : testMethods) {
                        testCount++;
                        out.append("console.log('    testing " + method.getName() + "');\n");
                        var jsMethodName = tr.methodNameRegistry.getNonGenericName(item.getFullName(),
                                method.getName());
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
        tr.out.append("})()");
        return tr.out;
    }

    private final CJIRContext ctx;
    private final CJJSSink out = new CJJSSink();
    private final CJJSMethodNameRegistry methodNameRegistry = new CJJSMethodNameRegistry();
    private final CJJSTempVarFactory varFactory = new CJJSTempVarFactory();
    private final Deque<CJJSReifiedMethod> todoMethods = Deque.of();
    private final Set<String> queuedMethods = Set.of();
    private final Deque<Pair<CJJSReifiedType, CJIRField>> todoStaticFields = Deque.of();
    private final Set<String> queuedStaticFields = Set.of();
    private final Deque<Pair<String, CJMark>> todoNatives = Deque.of();
    private final Set<String> queuedNatives = Set.of();

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

    private void queueNative(String fileName, CJMark mark) {
        if (!queuedNatives.contains(fileName)) {
            queuedNatives.add(fileName);
            todoNatives.add(Pair.of(fileName, mark));
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
        queueMethod(new CJJSReifiedMethod(owner, method, CJJSTypeBinding.empty(owner)));
    }

    public void emitQueued() {
        while (todoMethods.size() > 0) {
            var reifiedMethod = todoMethods.popLeft();
            emitMethod(reifiedMethod);
        }
        while (todoStaticFields.size() > 0) {
            var pair = todoStaticFields.popLeft();
            emitStaticField(pair.get1(), pair.get2());
        }
        while (todoNatives.size() > 0) {
            var pair = todoNatives.popLeft();
            emitNative(pair.get1(), pair.get2());
        }
    }

    private void emitNative(String fileName, CJMark mark) {
        var path = FS.join(jsroot, fileName);
        if (FS.isFile(path)) {
            out.addMark(CJMark.of(path, 1, 1));
            out.append(IO.readFile(path));
        } else {
            // TODO: uncomment this later
            // throw CJError.of("File " + fileName + " not found", mark);
            IO.println("MISSED " + fileName);
        }

        var deps = nativeDepMap.getOrNull(fileName);
        if (deps != null) {
            for (var dep : deps) {
                queueNative(dep, mark);
            }
        }
    }

    private void emitMallocMethod(CJJSReifiedMethod reifiedMethod) {
        var method = reifiedMethod.getMethod();
        var owner = reifiedMethod.getOwner();
        var methodName = methodNameRegistry.nameForReifiedMethod(reifiedMethod);
        var fields = owner.getItem().getFields().filter(f -> !f.isStatic());
        out.append("function ");
        out.addMark(method.getMark());
        out.append(methodName);
        out.append("(");
        var first = true;
        for (var field : fields) {
            if (field.getExpression().isEmpty() && !field.isLateinit()) {
                if (!first) {
                    out.append(",");
                }
                out.append("L$" + field.getName());
                first = false;
            }
        }
        out.append("){");
        for (var field : fields) {
            if (field.getExpression().isPresent()) {
                var expressionTranslator = new CJJSExpressionTranslator2(varFactory, methodNameRegistry,
                        CJJSTypeBinding.empty(owner), this::queueMethod, this::queueNative);
                var init = expressionTranslator.translate(field.getExpression().get());
                init.emitSet(out, "const L$" + field.getName() + "=");
            }
        }
        out.append("return[");
        first = true;
        for (var field : fields) {
            if (!first) {
                out.append(",");
            }
            if (field.isLateinit()) {
                out.append("undefined");
            } else {
                out.append("L$" + field.getName());
            }
            first = false;
        }
        out.append("]}");
    }

    private void emitMethod(CJJSReifiedMethod reifiedMethod) {
        IO.println("EMITTING " + reifiedMethod.getMethod().getName() + " " + reifiedMethod.getBinding());
        var method = reifiedMethod.getMethod();
        if (method.getBody().isEmpty()) {
            if (reifiedMethod.getMethod().getName().equals("__malloc")) {
                emitMallocMethod(reifiedMethod);
            } else {
                var extra = method.getExtra();
                if (extra instanceof CJIRFieldMethodInfo) {
                    var fmi = (CJIRFieldMethodInfo) extra;
                    var field = fmi.getField();
                    if (field.isStatic()) {
                        queueStaticField(reifiedMethod.getOwner(), field);
                    }
                }
            }
            return;
        }
        var binding = reifiedMethod.getBinding();
        var methodName = methodNameRegistry.nameForReifiedMethod(reifiedMethod);
        IO.println("  (NAME = " + methodName + ")");
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
        varFactory.reset();
        var expressionTranslator = new CJJSExpressionTranslator2(varFactory, methodNameRegistry, binding,
                this::queueMethod, this::queueNative);
        var blob = expressionTranslator.translate(method.getBody().get());
        blob.emitSet(out, "return ");
        out.append("}\n");
    }

    private void emitStaticField(CJJSReifiedType owner, CJIRField field) {
        var rootName = owner.toString().replace(".", "$") + "$" + field.getName();
        var fieldVarName = "FV$" + rootName;
        var getterName = owner.toString().replace(".", "$") + "$__get_" + field.getName();
        out.addMark(field.getMark());
        var cinit = field.getExpression().isPresent() ? getConstOrNull(field.getExpression().get()) : null;
        if (cinit != null) {
            out.append("function " + getterName + "(){return " + fieldVarName + "}");
            if (!field.isMutable()) {
                out.append("const " + fieldVarName + "=" + cinit + ";\n");
            } else {
                out.append("let " + fieldVarName + "=" + cinit + ";\n");
            }
        } else {
            out.append("let " + fieldVarName + ";\n");
            out.append("function " + getterName + "(){");
            out.append("if(" + fieldVarName + "===undefined){");
            if (field.getExpression().isPresent()) {
                var expressionTranslator = new CJJSExpressionTranslator2(varFactory, methodNameRegistry,
                        CJJSTypeBinding.empty(owner), this::queueMethod, this::queueNative);
                var init = expressionTranslator.translate(field.getExpression().get());
                init.emitSet(out, fieldVarName + "=");
            } else {
                out.append("throw new Error(\"Field used before being set\")");
            }
            out.append("}");
            out.append("return " + fieldVarName);
            out.append("}\n");
        }

        if (field.isMutable()) {
            var setterName = owner.toString().replace(".", "$") + "$__set_" + field.getName();
            out.append("function " + setterName + "(x){" + fieldVarName + "=x}\n");

            if (field.getType().repr().equals("cj.Int")) {
                var augName = owner.toString().replace(".", "$") + "$__augadd_" + field.getName();
                out.append("function " + augName + "(x){" + fieldVarName + "=" + getterName + "()+x}\n");
            }
        }
    }

    private String getConstOrNull(CJIRExpression expr) {
        if (expr instanceof CJIRLiteral) {
            var lit = (CJIRLiteral) expr;
            switch (lit.getKind()) {
            case Unit:
                return "undefined";
            case Char:
                return "" + CJToken.charLiteralToInt(lit.getRawText(), lit.getMark());
            case Bool:
            case Int:
            case Double:
            case String:
            case BigInt:
                return lit.getRawText();
            }
        } else if (expr instanceof CJIRNullWrap) {
            var nw = (CJIRNullWrap) expr;
            if (nw.getInner().isEmpty()) {
                return "null";
            }
        }
        return null;
    }
}
