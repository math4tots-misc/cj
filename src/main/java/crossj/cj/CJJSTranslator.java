package crossj.cj;

import crossj.base.Assert;
import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Range;
import crossj.base.Set;
import crossj.base.Str;

public final class CJJSTranslator extends CJJSTranslatorBase {
    private static final String jsroot = FS.join("src", "main", "resources", "js");

    private final CJJSSink out;

    public static CJJSSink translate(CJIRContext irctx, CJIRRunMode runMode) {
        var out = new CJJSSink();
        var jsctx = new CJJSContext();
        out.append("(function(){\n");
        out.append("\"use strict\";\n");
        emitPrelude(out);
        translateItems(out, irctx, jsctx);
        runMode.accept(new CJIRRunModeVisitor<Void, Void>() {
            @Override
            public Void visitMain(CJIRRunModeMain m, Void a) {
                var mainClass = translateItemMetaObjectName(m.getMainClass());
                out.append(mainClass + "." + translateMethodName("main") + "();\n");
                return null;
            }

            private void handleWWW(CJIRRunModeWWWBase m) {
                var mainClass = translateItemMetaObjectName(m.getMainClass());
                out.append("window.onload = () => {");
                out.append(mainClass + "." + translateMethodName("main") + "();");
                out.append("}\n");
            }

            @Override
            public Void visitWWW(CJIRRunModeWWW m, Void a) {
                handleWWW(m);
                return null;
            }

            @Override
            public Void visitTest(CJIRRunModeTest m, Void a) {
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
                    var metaObjectName = translateItemMetaObjectName(item.getFullName());
                    out.append("console.log('in " + item.getFullName() + "');\n");
                    for (var method : testMethods) {
                        testCount++;
                        out.append("console.log('    testing " + method.getName() + "');\n");
                        var methodName = translateMethodName(method.getName());
                        out.append(metaObjectName + "." + methodName + "();\n");
                    }
                }
                out.append("console.log('" + testCount + " tests in " + itemCount + " items pass');\n");
                return null;
            }

            @Override
            public Void visitNW(CJIRRunModeNW m, Void a) {
                handleWWW(m);
                return null;
            }
        }, null);
        out.append("})();\n");
        return out;
    }

    private static void emitPrelude(CJJSSink out) {
        var path = FS.join(jsroot, "prelude.js");
        out.append(IO.readFile(path));
    }

    private static void translateItems(CJJSSink out, CJIRContext irctx, CJJSContext jsctx) {
        var items = irctx.getAllLoadedItems();

        // emit meta classes (i.e. class MC$* { .. })
        for (var item : items) {
            translateItem(out, jsctx, item);
        }

        // add methods that allow traits to access their type variables
        for (var item : items) {
            if (!item.isTrait()) {
                addTypeVariableMethods(out, jsctx, item);
            }
        }

        // inherit trait methods
        for (var item : items) {
            if (!item.isTrait()) {
                inheritMethods(out, item);
            }
        }

        // emit meta objects (i.e. const MO$* = MC$*)
        // traits and items with type parameters will not have meta objects.
        for (var item : items) {
            if (!item.isTrait()) {
                // Even if the type has type parameters, we create a meta object for
                // calling generic methods with.
                var itemName = item.getFullName();
                out.append("const " + translateItemMetaObjectName(itemName) + "=new "
                        + translateItemMetaClassName(itemName) + "();\n");
            }
        }
    }

    private static void addTypeVariableMethods(CJJSSink out, CJJSContext jsctx, CJIRItem item) {
        var itemMetaClassName = translateItemMetaClassName(item.getFullName());
        var translator = new CJJSTranslator(out, jsctx, item);
        CJIRContextBase.walkTraits(item.toFullyImplementingTraitOrClassType(), trait -> {
            var params = trait.getItem().getTypeParameters();
            var args = trait.getArgs();
            for (int i = 0; i < args.size(); i++) {
                var typeMethodName = translateTraitLevelTypeVariableNameWithTraitName(trait.getItem().getFullName(),
                        params.get(i).getName());
                out.append(itemMetaClassName + ".prototype." + typeMethodName + "=function(){");
                out.append("return " + translator.translateType(args.get(i)) + "}\n");
            }
            return null;
        });
    }

    private static void inheritMethods(CJJSSink out, CJIRItem item) {
        var itemMetaClassName = translateItemMetaClassName(item.getFullName());
        var seenMethods = Set.fromIterable(item.getMethods().map(m -> m.getName()));
        CJIRContextBase.walkTraits(item.toFullyImplementingTraitOrClassType(), trait -> {
            var traitMetaClassName = translateItemMetaClassName(trait.getItem().getFullName());
            for (var method : trait.getItem().getMethods()) {
                if (!seenMethods.contains(method.getName())) {
                    if (method.hasImpl()) {
                        seenMethods.add(method.getName());
                        var jsMethodName = translateMethodName(method.getName());
                        out.append(itemMetaClassName + ".prototype." + jsMethodName + "=" + traitMetaClassName
                                + ".prototype." + jsMethodName + ";\n");
                    }
                }
            }
            return null;
        });
    }

    private static void translateItem(CJJSSink out, CJJSContext ctx, CJIRItem item) {
        new CJJSTranslator(out, ctx, item).emitItem();
    }

    CJJSTranslator(CJJSSink out, CJJSContext ctx, CJIRItem item) {
        super(ctx, item, item.isTrait() ? null
                : new CJIRClassType(item, item.getTypeParameters().map(tp -> new CJIRVariableType(tp, List.of()))));
        this.out = out;
    }

    // private boolean inAsyncContext = false;

    private void emitItem() {
        if (item.isNative()) {
            out.addMark(item.getMark());
            var path = FS.join(jsroot, item.getFullName() + ".js");
            if (!FS.exists(path)) {
                // If the file doesn't exist, and it's non-generic, create a dummy
                var metaClassName = translateItemMetaClassName(item.getFullName());
                out.append("class " + metaClassName + "{\n");
                emitMetaClassConstructor(item);
                emitMethods(item, true);
                out.append("}\n");
            } else {
                var contents = IO.readFile(path);
                if (contents.startsWith("//!") || contents.contains("\n//!")) {
                    for (var line : contents.split("\n")) {
                        if (line.trim().startsWith("//!")) {
                            var includePath = FS.join(jsroot, line.trim().substring(3).trim());
                            out.append(IO.readFile(includePath));
                        }
                    }
                }
                out.append(contents);
                emitMethods(item, false); // we still want to use the methods that have a body
            }
        } else {
            emitMetaClass();
        }
    }

    private void emitMetaClassConstructor(CJIRItem item) {
        if (!item.isTrait() && item.getTypeParameters().size() > 0) {
            var args = item.getTypeParameters().map(p -> translateMethodLevelTypeVariable(p.getName()));
            out.append("constructor(" + Str.join(",", args) + "){");
            for (var arg : args) {
                out.append("this." + arg + "=" + arg + ";");
            }
            out.append("}\n");
        }
    }

    private void emitMetaClass() {
        var metaClassName = translateItemMetaClassName(item.getFullName());
        out.append("class " + metaClassName + "{\n");
        emitMetaClassConstructor(item);

        // emit static fields
        for (var field : item.getFields().filter(f -> f.isStatic())) {
            var getterMethodName = translateMethodName(field.getGetterName());
            var fieldName = translateFieldName(field.getName());
            out.append(getterMethodName + "(){");
            out.append("if(!('" + fieldName + "' in this)){");
            if (field.isLateinit()) {
                out.append("throw new Error('lateinit field used before init')");
            } else {
                var blob = translateExpression(field.getExpression().get());
                blob.emitPrep(out);
                out.append("this." + fieldName + "=");
                blob.emitMain(out);
                out.append(";");
            }
            out.append("}");
            out.append("return this." + fieldName + ";");
            out.append("}\n");
            if (field.isMutable()) {
                var setterMethodName = translateMethodName(field.getSetterName());
                out.append(setterMethodName + "(x){this." + fieldName + "=x;}\n");
            }
        }

        // for (non-union) classes: emit non-static fields and malloc
        if ((item.getKind() == CJIRItemKind.Class || item.getKind() == CJIRItemKind.Interface) && !item.isNative()) {
            var nonStaticFields = item.getFields().filter(f -> !f.isStatic());
            var argFields = nonStaticFields.filter(f -> f.includeInMalloc());
            if (isWrapperItem(item)) {
                // wrapper type
                // there is exactly 1 non-static field, and it is immutable
                Assert.equals(nonStaticFields.size(), 1);
                var field = nonStaticFields.get(0);
                Assert.that(!field.isMutable());
                var getterMethodName = translateMethodName(field.getGetterName());
                out.append(getterMethodName + "(a){return a}\n");
                var mallocMethodName = translateMethodName("__malloc");
                if (field.getExpression().isPresent()) {
                    var expr = translateExpression(field.getExpression().get());
                    out.append(mallocMethodName + "(){");
                    expr.emitPrep(out);
                    out.append("return ");
                    expr.emitMain(out);
                    out.append("}\n");
                } else {
                    out.append(mallocMethodName + "(a){return a}\n");
                }
            } else {
                for (var field : nonStaticFields) {
                    var index = field.getIndex();
                    var getterMethodName = translateMethodName(field.getGetterName());
                    if (field.isLateinit()) {
                        out.append(getterMethodName + "(a){return defined(a[" + index + "])}\n");
                    } else {
                        out.append(getterMethodName + "(a){return a[" + index + "]}\n");
                    }
                    if (field.isMutable()) {
                        var setterMethodName = translateMethodName(field.getSetterName());
                        out.append(setterMethodName + "(a,x){a[" + index + "]=x}\n");
                    }
                }
                var mallocMethodName = translateMethodName("__malloc");
                if (nonStaticFields.isEmpty()) {
                    out.append(mallocMethodName + "(){return undefined;}\n");
                } else {
                    var argnames = Str.join(",", Range.upto(argFields.size()).map(i -> "a" + i));
                    if (nonStaticFields.all(f -> f.includeInMalloc())) {
                        out.append(mallocMethodName + "(" + argnames + "){return [" + argnames + "]}\n");
                    } else {
                        out.append(mallocMethodName + "(" + argnames + "){");
                        var initexprs = List.<CJJSBlob>of();
                        {
                            int i = 0;
                            for (var field : nonStaticFields) {
                                if (field.includeInMalloc()) {
                                    initexprs.add(CJJSBlob.pure("a" + (i++)));
                                } else if (field.isLateinit()) {
                                    initexprs.add(CJJSBlob.pure("undefined"));
                                } else {
                                    var expr = translateExpression(field.getExpression().get()).toPure(ctx);
                                    expr.emitPrep(out);
                                    initexprs.add(expr);
                                }
                            }
                        }
                        out.append("return [");
                        for (int i = 0; i < initexprs.size(); i++) {
                            if (i > 0) {
                                out.append(",");
                            }
                            initexprs.get(i).emitMain(out);
                        }
                        out.append("]}\n");
                    }
                }
            }
        }

        // for unions: emit tag method and case constructors
        if (item.getKind() == CJIRItemKind.Union && !item.isNative()) {
            for (var caseDefn : item.getCases()) {
                var methodName = translateMethodName(caseDefn.getName());
                var argc = caseDefn.getTypes().size();
                var args = Str.join(",", Range.upto(argc).map(i -> "a" + i));
                if (item.isSimpleUnion()) {
                    out.append(methodName + "(" + args + "){return " + caseDefn.getTag() + ";}\n");
                } else {
                    out.append(methodName + "(" + args + "){return[" + caseDefn.getTag() + "," + args + "];}\n");
                }
            }
        }
        emitMethods(item, true);
        out.append("}\n");
    }

    private void emitMethods(CJIRItem item, boolean inline) {
        for (var method : item.getMethods()) {
            var optionalBody = method.getBody();
            if (optionalBody.isPresent()) {
                emitMethod(item, method, inline);
            }
        }
    }

    private void emitMethod(CJIRItem item, CJIRMethod method, boolean inline) {
        var methodName = translateMethodName(method.getName());
        var typeArgNames = method.getTypeParameters().map(p -> translateMethodLevelTypeVariable(p.getName()));
        var argNames = method.getParameters().map(p -> translateLocalVariableName(p.getName()));
        var allArgNames = List.of(typeArgNames, argNames).flatMap(x -> x);
        var prefix = method.isAsync() ? "async " : "";
        if (inline) {
            out.append(prefix);
            out.addMark(method.getMark());
            out.append(methodName);
        } else {
            var metaClassName = translateItemMetaClassName(item.getFullName());
            out.addMark(method.getMark());
            out.append(metaClassName + ".prototype." + methodName  + "=" + prefix + "function");
        }
        out.append("(" + Str.join(",", allArgNames) + "){");
        // inAsyncContext = method.isAsync();
        var body = translateExpression(method.getBody().get());
        body.emitPrep(out);
        if (method.getReturnType().isUnitType() || method.getReturnType().isNoReturnType()) {
            if (!body.isPure()) {
                body.emitMain(out);
                out.append(";");
            }
        } else {
            out.append("return ");
            body.emitMain(out);
            out.append(";");
        }
        out.append("}\n");
        // inAsyncContext = false;
    }

    private CJJSBlob translateExpression(CJIRExpression expression) {
        return new CJJSExpressionTranslator(ctx, item, selfType).translateExpression(expression);
    }
}
