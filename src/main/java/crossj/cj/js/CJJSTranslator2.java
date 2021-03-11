package crossj.cj.js;

import crossj.base.Assert;
import crossj.base.Deque;
import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Pair;
import crossj.base.Set;
import crossj.cj.CJError;
import crossj.cj.CJIRCaseMethodInfo;
import crossj.cj.CJIRClassType;
import crossj.cj.CJIRContext;
import crossj.cj.CJIRExpression;
import crossj.cj.CJIRField;
import crossj.cj.CJIRFieldMethodInfo;
import crossj.cj.CJIRItem;
import crossj.cj.CJIRLiteral;
import crossj.cj.CJIRNullWrap;
import crossj.cj.CJIRRunMode;
import crossj.cj.CJIRRunModeMain;
import crossj.cj.CJIRRunModeTest;
import crossj.cj.CJIRRunModeVisitor;
import crossj.cj.CJIRRunModeWWW;
import crossj.cj.CJIRType;
import crossj.cj.CJJSSink;
import crossj.cj.CJMark;
import crossj.cj.CJToken;

public final class CJJSTranslator2 {
    private static final String jsroot = FS.join("src", "main", "resources", "js2");

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
                for (var item : items) {
                    if (!item.isTrait() && item.getTypeParameters().isEmpty()) {
                        for (var method : item.getMethods()) {
                            if (method.getTypeParameters().isEmpty()) {
                                tr.queueMethodByName(item.getFullName(), method.getName());
                            }
                        }
                    }
                }
                return null;
            }

            @Override
            public Void visitWWW(CJIRRunModeWWW m, Void a) {
                tr.queueMethodByName(m.getMainClass(), "main");
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
                var mainMethodName = tr.methodNameRegistry.getNonGenericName(m.getMainClass(), "main");
                tr.out.append("window.onload=" + mainMethodName + ";\n");
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
    private final Deque<CJJSLLMethod> todoMethods = Deque.of();
    private final Set<String> queuedMethods = Set.of();
    private final Deque<Pair<CJIRClassType, CJIRField>> todoStaticFields = Deque.of();
    private final Set<String> queuedStaticFields = Set.of();
    private final Deque<Pair<String, CJMark>> todoNatives = Deque.of();
    private final Set<String> queuedNatives = Set.of();
    private final CJJSTypeIdRegistry typeIdRegistry = new CJJSTypeIdRegistry();

    public CJJSTranslator2(CJIRContext ctx) {
        this.ctx = ctx;
    }

    public void queueMethod(CJJSLLMethod reifiedMethod) {
        var id = reifiedMethod.getId();
        if (!queuedMethods.contains(id)) {
            queuedMethods.add(id);
            todoMethods.add(reifiedMethod);
        }
    }

    public void queueStaticField(CJIRClassType owner, CJIRField field) {
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

        var key = itemName + "." + methodName;
        if (CJJSOps.OPS.containsKey(key)) {
            // this is a method that's handled inline by CJJSOps.
            return;
        }

        var owner = new CJIRClassType(item, List.of());
        queueMethod(new CJJSLLMethod(owner, method, CJJSTypeBinding.empty(owner)));
    }

    public void emitQueued() {
        while (todoMethods.size() > 0 || todoStaticFields.size() > 0 || todoNatives.size() > 0) {
            if (todoMethods.size() > 0) {
                var reifiedMethod = todoMethods.popLeft();
                emitMethod(reifiedMethod);
            } else if (todoStaticFields.size() > 0) {
                var pair = todoStaticFields.popLeft();
                emitStaticField(pair.get1(), pair.get2());
            } else if (todoNatives.size() > 0) {
                var pair = todoNatives.popLeft();
                emitNative(pair.get1(), pair.get2());
            } else {
                Assert.that(false);
            }
        }
    }

    private void emitNative(String fileName, CJMark mark) {
        var path = FS.join(jsroot, fileName);
        if (FS.isFile(path)) {
            var contents = IO.readFile(path);
            var deps = List.<String>of();
            for (var line : contents.split("\n")) {
                if (line.startsWith("//!!")) {
                    deps.add(line.substring(4).trim());
                }
            }
            out.addMark(CJMark.of(path, 1, 1));
            out.append(contents);
            for (var dep : deps) {
                queueNative(dep, mark);
            }
        } else {
            // TODO: uncomment this later
            // throw CJError.of("File " + fileName + " not found", mark);
            IO.println("MISSED " + fileName);
        }
    }

    private void emitMallocMethod(CJJSLLMethod reifiedMethod) {
        var method = reifiedMethod.getMethod();
        var owner = reifiedMethod.getOwner();
        var isWrapper = isWrapperType(owner);
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
                // TODO: Consider whether a fuller binding is needed here
                var expressionTranslator = newExpressionTranslator(CJJSTypeBinding.empty(owner));
                var init = expressionTranslator.translate(field.getExpression().get());
                init.emitSet(out, "const L$" + field.getName() + "=");
            }
        }
        out.append("return ");
        if (!isWrapper) {
            out.append("[");
        }
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
        if (!isWrapper) {
            out.append("]");
        }
        out.append("}");
    }

    private void emitMethod(CJJSLLMethod reifiedMethod) {
        IO.println("EMITTING " + reifiedMethod.getMethod().getName() + " " + reifiedMethod.getBinding().getIdStr());
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
                } else if (extra instanceof CJIRCaseMethodInfo) {
                    // it's ok to omit here -- should be always implemented
                    // directly in CJJSOps
                } else if (reifiedMethod.getOwner().isNative()) {
                    var key = reifiedMethod.getOwner().getItem().getFullName() + "."
                            + reifiedMethod.getMethod().getName();
                    var path = FS.join(jsroot, key + ".js");
                    if (FS.exists(path)) {
                        emitNative(key + ".js", method.getMark());
                        var name = methodNameRegistry.nameForReifiedMethod(reifiedMethod);
                        IO.println("  (NATIVE " + name + ")");
                    } else {
                        if (CJJSOps.OPS.containsKey(key)) {
                            // probably ok
                        } else {
                            // TODO: Considering throwing here
                            var name = methodNameRegistry.nameForReifiedMethod(reifiedMethod);
                            IO.println("  (MISSING-NATIVE " + name + ")");
                        }
                    }
                } else {
                    var key = reifiedMethod.getOwner().getItem().getFullName() + "." + method.getName();
                    if (CJJSOps.OPS.containsKey(key)) {
                        // probably ok
                    } else {
                        // TODO: Considering throwing here
                        var name = methodNameRegistry.nameForReifiedMethod(reifiedMethod);
                        IO.println("  (MISSING " + name + ")");
                    }
                }
            }
            return;
        }
        var binding = reifiedMethod.getBinding();
        var methodName = methodNameRegistry.nameForReifiedMethod(reifiedMethod);
        IO.println("  (NAME = " + methodName + ")");
        if (method.isAsync()) {
            out.append("async ");
        }
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
        var expressionTranslator = newExpressionTranslator(binding);
        var blob = expressionTranslator.translate(method.getBody().get());
        blob.emitSet(out, "return ");
        out.append("}\n");
    }

    private void emitStaticField(CJIRClassType owner, CJIRField field) {
        var rootName = owner.repr().replace(".", "$") + "$" + field.getName();
        var fieldVarName = "FV$" + rootName;
        var getterName = owner.repr().replace(".", "$") + "$__get_" + field.getName();
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
                var expressionTranslator = newExpressionTranslator(CJJSTypeBinding.empty(owner));
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
            var setterName = owner.repr().replace(".", "$") + "$__set_" + field.getName();
            out.append("function " + setterName + "(x){" + fieldVarName + "=x}\n");

            if (field.getType().repr().equals("cj.Int")) {
                var augName = owner.repr().replace(".", "$") + "$__augadd_" + field.getName();
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

    private CJJSExpressionTranslator2 newExpressionTranslator(CJJSTypeBinding binding) {
        return new CJJSExpressionTranslator2(typeIdRegistry, varFactory, methodNameRegistry, binding, this::queueMethod,
                this::queueNative);
    }

    static boolean isWrapperType(CJIRType type) {
        if (!(type instanceof CJIRClassType)) {
            return false;
        }
        var item = ((CJIRClassType) type).getItem();
        return isWrapperItem(item);
    }

    static boolean isWrapperItem(CJIRItem item) {
        // check that there's exactly 1 non-static field
        var nonStaticFields = item.getFields().filter(f -> !f.isStatic());
        if (nonStaticFields.size() != 1) {
            return false;
        }
        var field = nonStaticFields.get(0);

        // check that the field is immutable
        if (field.isMutable()) {
            return false;
        }

        // check that the field's type is not nullable
        if (!field.getType().getTraits().any(t -> t.getItem().getFullName().equals("cj.NonNull"))) {
            return false;
        }

        return true;
    }
}
