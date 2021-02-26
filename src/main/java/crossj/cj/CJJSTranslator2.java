package crossj.cj;

import crossj.base.Assert;
import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Pair;
import crossj.base.Range;
import crossj.base.Set;
import crossj.base.Str;

public final class CJJSTranslator2 extends CJJSTranslatorBase2 {
    private static final String jsroot = FS.join("src", "main", "resources", "js");

    public static String translate(CJIRContext irctx, boolean enableStack, CJIRRunMode runMode) {
        var out = new CJJSSink();
        var jsctx = new CJJSContext(enableStack);
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

            @Override
            public Void visitWWW(CJIRRunModeWWW m, Void a) {
                var mainClass = translateItemMetaObjectName(m.getMainClass());
                out.append("window.onload = () => {\n");
                out.append(mainClass + "." + translateMethodName("main") + "();\n");
                out.append("}\n");
                return null;
            }

            @Override
            public Void visitTest(CJIRRunModeTest m, Void a) {
                var items = irctx.getAllLoadedItems();
                int testCount = 0;
                int itemCount = 0;
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
        }, null);
        out.append("})();\n");
        return out.getSource();
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
        var translator = new CJJSTranslator2(out, jsctx, item);
        CJIRContextBase.walkTraits(item.toFullyImplementingTraitOrClassType(), trait -> {
            var params = trait.getItem().getTypeParameters();
            var args = trait.getArgs();
            for (int i = 0; i < args.size(); i++) {
                var typeMethodName = translateTraitLevelTypeVariableNameWithTraitName(trait.getItem().getFullName(),
                        params.get(i).getName());
                out.append(itemMetaClassName + ".prototype." + typeMethodName + "=function(){\n");
                out.append("return " + translator.translateType(args.get(i)) + ";\n");
                out.append("}\n");
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
        new CJJSTranslator2(out, ctx, item).emitItem();
    }

    CJJSTranslator2(CJJSSink out, CJJSContext ctx, CJIRItem item) {
        super(out, ctx, item, item.isTrait() ? null
                : new CJIRClassType(item, item.getTypeParameters().map(tp -> new CJIRVariableType(tp, List.of()))));
    }

    // private boolean inAsyncContext = false;

    private void emitItem() {
        if (item.isNative()) {
            out.append(IO.readFile(FS.join(jsroot, item.getFullName() + ".js")));
        } else {
            emitMetaClass();
        }
    }

    private void emitMetaClass() {
        var metaClassName = translateItemMetaClassName(item.getFullName());
        out.append("class " + metaClassName + "{\n");
        if (!item.isTrait() && item.getTypeParameters().size() > 0) {
            var args = item.getTypeParameters().map(p -> translateMethodLevelTypeVariable(p.getName()));
            out.append("constructor(" + Str.join(",", args) + "){\n");
            for (var arg : args) {
                out.append("this." + arg + "=" + arg + ";\n");
            }
            out.append("}\n");
        }

        // emit static fields
        for (var field : item.getFields().filter(f -> f.isStatic())) {
            var getterMethodName = translateMethodName(field.getGetterName());
            var fieldName = translateFieldName(field.getName());
            out.append(getterMethodName + "(){\n");
            out.append("if (!('" + fieldName + "' in this)){\n");
            if (field.isLateinit()) {
                out.append("throw new Error('lateinit field used before init')");
            } else {
                var blob = translateExpression(field.getExpression().get());
                blob.getLines().forEach(out::append);
                out.append("this." + fieldName + "=" + blob.getExpression() + ";\n");
            }
            out.append("}\n");
            out.append("return this." + fieldName + ";\n");
            out.append("}\n");
            if (field.isMutable()) {
                var setterMethodName = translateMethodName(field.getSetterName());
                out.append(setterMethodName + "(x){this." + fieldName + "=x;}\n");
            }
        }

        // for (non-union) classes: emit non-static fields and malloc
        if (item.getKind() == CJIRItemKind.Class && !item.isNative()) {
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
                    out.append(mallocMethodName + "(){\n");
                    for (var line : expr.getLines()) {
                        out.append(line);
                    }
                    out.append("return " + expr.getExpression() + ";\n");
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
                        out.append(mallocMethodName + "(" + argnames + "){\n");
                        var values = List.<String>of();
                        {
                            int i = 0;
                            for (var field : nonStaticFields) {
                                if (field.includeInMalloc()) {
                                    values.add("a" + (i++));
                                } else if (field.isLateinit()) {
                                    values.add("undefined");
                                } else {
                                    var expr = translateExpression(field.getExpression().get()).toPure(ctx);
                                    for (var line : expr.getLines()) {
                                        out.append(line);
                                    }
                                    values.add(expr.getExpression());
                                }
                            }
                        }
                        out.append("return [" + Str.join(",", values) + "];\n");
                        out.append("}\n");
                    }
                }
            }
        }

        // for unions: emit case constructors
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

        for (var method : item.getMethods()) {
            var optionalBody = method.getBody();
            if (optionalBody.isPresent()) {
                var methodName = translateMethodName(method.getName());
                var typeArgNames = method.getTypeParameters().map(p -> translateMethodLevelTypeVariable(p.getName()));
                var argNames = method.getParameters().map(p -> translateLocalVariableName(p.getName()));
                var allArgNames = List.of(typeArgNames, argNames).flatMap(x -> x);
                var prefix = method.isAsync() ? "async " : "";
                out.append(prefix + methodName + "(" + Str.join(",", allArgNames) + "){\n");
                // inAsyncContext = method.isAsync();
                var body = translateExpression(optionalBody.get());
                for (var line : body.getLines()) {
                    out.append(line);
                }
                if (method.getReturnType().isUnitType()) {
                    if (!body.isPure()) {
                        out.append(body.getExpression() + ";\n");
                    }
                } else {
                    out.append("return " + body.getExpression() + ";\n");
                }
                out.append("}\n");
                // inAsyncContext = false;
            }
        }
        out.append("}\n");
    }

    private CJJSBlob translateExpression(CJIRExpression expression) {
        return expression.accept(new CJIRExpressionVisitor<CJJSBlob, Void>() {

            @Override
            public CJJSBlob visitLiteral(CJIRLiteral e, Void a) {
                switch (e.getKind()) {
                    case Unit:
                        return CJJSBlob.inline("undefined", true);
                    case Char:
                        return CJJSBlob.inline("" + CJToken.charLiteralToInt(e.getRawText(), e.getMark()), true);
                    case Bool:
                    case Int:
                    case Double:
                    case String:
                    case BigInt:
                        return CJJSBlob.inline(e.getRawText(), true);
                }
                throw CJError.of("TODO: " + e.getKind(), e.getMark());
            }

            @Override
            public CJJSBlob visitBlock(CJIRBlock e, Void a) {
                var exprs = e.getExpressions();
                var returns = !e.getType().isUnitType();
                var tmpvar = returns ? ctx.newTempVarName() : "undefined";
                var lines = List.of(returns ? "let " + tmpvar + ";" : "");
                lines.add("{\n");
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    translateExpression(exprs.get(i)).dropValue(lines);
                }
                var last = translateExpression(exprs.last());
                if (returns) {
                    last.setValue(lines, tmpvar + "=");
                } else {
                    last.dropValue(lines);
                }
                lines.add("}\n");
                return new CJJSBlob(lines, tmpvar, true);
            }

            @Override
            public CJJSBlob visitMethodCall(CJIRMethodCall e, Void a) {
                var typeArgs = e.getMethodRef().isGeneric() ? e.getTypeArgs().map(i -> "null")
                        : translateTypeArgs(e.getMethodRef().getMethod().getTypeParameters(), e.getTypeArgs());
                var args = e.getArgs().map(CJJSTranslator2.this::translateExpression);
                args = args.all(arg -> arg.isSimple()) ? args : args.map(arg -> arg.toPure(ctx));
                var lines = List.<String>of();
                for (var arg : args) {
                    lines.addAll(arg.getLines());
                }
                var allArgs = List.of(typeArgs, args.map(arg -> arg.getExpression())).flatMap(x -> x);
                var pair = joinMethodCall(lines, e.getMark(), e.getOwner(), e.getMethodRef(), e.getArgs(), allArgs);
                return new CJJSBlob(lines, pair.get1(), pair.get2());
            }

            private Pair<String, Boolean> joinMethodCall(List<String> lines, CJMark mark, CJIRType owner,
                    CJIRMethodRef methodRef, List<CJIRExpression> args, List<String> allArgs) {
                var fullMethodName = methodRef.getOwner().getItem().getFullName() + "." + methodRef.getName();
                switch (fullMethodName) {
                    case "cj.Int.__neg":
                        return Pair.of("(-" + allArgs.get(0) + ")", false);
                    case "cj.Int.__add":
                        return Pair.of("((" + Str.join("+", allArgs) + ")|0)", false);
                    case "cj.Int.__mul":
                        return Pair.of("((" + Str.join("*", allArgs) + ")|0)", false);
                    case "cj.Int.__sub":
                        return Pair.of("((" + Str.join("-", allArgs) + ")|0)", false);
                    case "cj.Int.__truncdiv":
                        return Pair.of("((" + Str.join("/", allArgs) + ")|0)", false);
                    case "cj.Int.__div":
                        return Pair.of("(" + Str.join("/", allArgs) + ")", false);
                    case "cj.Int.__or":
                        return Pair.of("(" + Str.join("|", allArgs) + ")", false);
                    case "cj.Int.__and":
                        return Pair.of("(" + Str.join("&", allArgs) + ")", false);
                    case "cj.Int.__lshift":
                        return Pair.of("(" + Str.join("<<", allArgs) + ")", false);
                    case "cj.Int.__rshift":
                        return Pair.of("(" + Str.join(">>", allArgs) + ")", false);
                    case "cj.Int.__rshiftu":
                        return Pair.of("(" + Str.join(">>>", allArgs) + ")", false);
                    case "cj.Double.__neg":
                        return Pair.of("(-" + allArgs.get(0) + ")", false);
                    case "cj.Double.__add":
                        return Pair.of("(" + Str.join("+", allArgs) + ")", false);
                    case "cj.Double.__mul":
                        return Pair.of("(" + Str.join("*", allArgs) + ")", false);
                    case "cj.Double.__sub":
                        return Pair.of("(" + Str.join("-", allArgs) + ")", false);
                    case "cj.Double.__truncdiv":
                        return Pair.of("((" + Str.join("/", allArgs) + ")|0)", false);
                    case "cj.Double.__div":
                        return Pair.of("(" + Str.join("/", allArgs) + ")", false);
                    case "cj.List.empty":
                        return Pair.of("[]", false);
                    case "cj.List_.empty":
                        return Pair.of("[]", false);
                    case "cj.List.__new":
                        Assert.equals(allArgs.size(), 1);
                        return Pair.of(allArgs.get(0), false);
                    case "cj.List.size":
                        Assert.equals(allArgs.size(), 1);
                        return Pair.of(allArgs.get(0) + ".length", false);
                    case "cj.String.__add":
                        Assert.equals(allArgs.size(), 3);
                        Assert.equals(args.size(), 2);
                        switch (args.get(1).getType().toRawQualifiedName()) {
                            case "cj.String":
                            case "cj.Int":
                            case "cj.Double":
                            case "cj.Bool":
                                return Pair.of("(" + allArgs.get(1) + "+" + allArgs.get(2) + ")", false);
                        }
                        break;
                    case "cj.Nullable.default":
                        Assert.equals(allArgs.size(), 0);
                        return Pair.of("null", true);
                    case "cj.Int.default":
                    case "cj.Double.default":
                    case "cj.Char.default":
                        Assert.equals(allArgs.size(), 0);
                        return Pair.of("0", true);
                    case "cj.List.default":
                        Assert.equals(allArgs.size(), 0);
                        return Pair.of("[]", false);
                    case "cj.js.JSObject.field":
                    case "cj.js.JSWrapper.field":
                        Assert.equals(allArgs.size(), 2);
                        return Pair.of(allArgs.get(0) + "[" + allArgs.get(1) + "]", false);
                    case "cj.js.JSObject.setField":
                    case "cj.js.JSWrapper.setField":
                        Assert.equals(allArgs.size(), 4);
                        lines.add(allArgs.get(1) + "[" + allArgs.get(2) + "]=" + allArgs.get(3) + ";\n");
                        return Pair.of("undefined", true);
                    case "cj.js.JSObject.call1":
                    case "cj.js.JSObject.call":
                    case "cj.js.JSWrapper.call": {
                        Assert.equals(allArgs.size(), 3);
                        var call = allArgs.get(0) + "[" + allArgs.get(1) + "](..." + allArgs.get(2) + ")";
                        return Pair.of(call, false);
                    }
                    case "cj.js.JSON.fromList":
                    case "cj.Double._fromInt":
                    case "cj.Double.toDouble":
                    case "cj.Int.toDouble":
                    case "cj.Int._fromChar":
                        Assert.equals(allArgs.size(), 1);
                        return Pair.of(allArgs.get(0), false);
                    case "cj.js.JSON._unsafeCast":
                    case "cj.js.JSObject.unsafeCast":
                        Assert.equals(allArgs.size(), 2);
                        return Pair.of(allArgs.get(1), false);
                    case "cj.Fn0":
                    case "cj.Fn1":
                    case "cj.Fn2":
                    case "cj.Fn3":
                    case "cj.Fn4": {
                        var call = allArgs.get(0) + "(" + Str.join(",", allArgs.sliceFrom(1)) + ")";
                        return Pair.of(call, false);
                    }
                }
                String ownerStr;
                if (methodRef.getMethod().isGenericSelf() && owner instanceof CJIRClassType) {
                    ownerStr = translateItemMetaObjectName(((CJIRClassType) owner).getItem().getFullName());
                } else {
                    ownerStr = translateType(owner);
                }

                var extra = methodRef.getMethod().getExtra();

                if (extra instanceof CJIRFieldMethodInfo) {
                    var info = (CJIRFieldMethodInfo) extra;
                    var field = info.getField();
                    if (field.isStatic()) {
                        var target = ownerStr + "." + translateFieldName(field.getName());
                        switch (info.getKind()) {
                            case "":
                                if (!field.isMutable() && field.getExpression().isPresent() &&
                                        field.getExpression().get() instanceof CJIRLiteral) {
                                    var literal = (CJIRLiteral) field.getExpression().get();
                                    var result = visitLiteral(literal, null);
                                    Assert.that(result.getLines().isEmpty());
                                    return Pair.of(result.getExpression(), true);
                                }
                                break;
                            case "=":
                                Assert.equals(allArgs.size(), 1);
                                return Pair.of(target + info.getKind() + allArgs.last(), false);
                            case "+=":
                                Assert.equals(allArgs.size(), 1);
                                return Pair.of(target + "=(" + ownerStr + "."
                                        + translateMethodName(field.getGetterName()) + "())" + "+" + allArgs.last(),
                                        false);
                        }
                    } else if (!field.isStatic()) {
                        var target = isWrapperType(owner) ? allArgs.get(0)
                                : allArgs.get(0) + "[" + field.getIndex() + "]";
                        switch (info.getKind()) {
                            case "":
                                Assert.equals(allArgs.size(), 1);
                                if (field.isLateinit()) {
                                    break;
                                }
                                return Pair.of(target, false);
                            case "=":
                            case "+=":
                                Assert.equals(allArgs.size(), 2);
                                Assert.that(field.isMutable());
                                return Pair.of(target + info.getKind() + allArgs.last(), false);
                        }
                    }
                }

                var call = ownerStr + "." + translateMethodName(methodRef.getName()) + "(" + Str.join(",", allArgs)
                        + ")";

                return Pair.of(call, false);
            }

            @Override
            public CJJSBlob visitVariableDeclaration(CJIRVariableDeclaration e, Void a) {
                var prefix = e.isMutable() ? "let " : "const ";
                var inner = translateExpression(e.getExpression());
                var lines = inner.getLines();
                lines.add(prefix + translateTarget(e.getTarget()) + "=" + inner.getExpression() + ";\n");
                return new CJJSBlob(lines, "undefined", true);
            }

            @Override
            public CJJSBlob visitVariableAccess(CJIRVariableAccess e, Void a) {
                return CJJSBlob.inline(translateLocalVariableName(e.getDeclaration().getName()), true);
            }

            @Override
            public CJJSBlob visitAssignment(CJIRAssignment e, Void a) {
                var expr = translateExpression(e.getExpression());
                var target = translateLocalVariableName(e.getVariableName());
                var lines = expr.getLines();
                lines.add(target + "=" + expr.getExpression() + ";\n");
                return new CJJSBlob(lines, "undefined", true);
            }

            private boolean isOne(CJIRExpression e) {
                if (e instanceof CJIRLiteral) {
                    var lit = (CJIRLiteral) e;
                    if (lit.getKind().equals(CJIRLiteralKind.Int) && lit.getRawText().equals("1")) {
                        return true;
                    }
                }
                return false;
            }

            @Override
            public CJJSBlob visitAugmentedAssignment(CJIRAugmentedAssignment e, Void a) {
                var target = translateLocalVariableName(e.getTarget().getName());
                var augexpr = translateExpression(e.getExpression());
                String op;
                switch (e.getKind()) {
                    case Add:
                        op = "+=";
                        break;
                    case Subtract:
                        op = "-=";
                        break;
                    case Multiply:
                        op = "*=";
                        break;
                    case Remainder:
                        op = "%=";
                        break;
                    default:
                        throw CJError.of("Unexpected aug op: " + e.getKind(), e.getMark());
                }
                var lines = augexpr.getLines();
                if (e.getKind() == CJIRAugAssignKind.Add && isOne(e.getExpression())) {
                    lines.add(target + "++;\n");
                } else if (e.getKind() == CJIRAugAssignKind.Subtract && isOne(e.getExpression())) {
                    lines.add(target + "--;\n");
                } else {
                    lines.add(target + op + augexpr.getExpression() + ";\n");
                }
                return new CJJSBlob(lines, "undefined", true);
            }

            @Override
            public CJJSBlob visitLogicalNot(CJIRLogicalNot e, Void a) {
                var inner = translateExpression(e.getInner());
                return new CJJSBlob(inner.getLines(), "(!" + inner.getExpression() + ")", inner.isPure());
            }

            @Override
            public CJJSBlob visitLogicalBinop(CJIRLogicalBinop e, Void a) {
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                if (left.isSimple() && right.isSimple()) {
                    var op = e.isAnd() ? "&&" : "||";
                    return CJJSBlob.inline("((" + left.getExpression() + ")" + op + "(" + right.getExpression() + "))",
                            false);
                } else {
                    var lines = left.getLines();
                    var tmpvar = ctx.newTempVarName();
                    lines.add("let " + tmpvar + "=" + (e.isAnd() ? "false" : "true") + ";\n");
                    lines.add("if(" + (e.isAnd() ? "" : "!") + "(" + left.getExpression() + ")){\n");
                    right.setValue(lines, tmpvar + "=");
                    lines.add("}\n");
                    return new CJJSBlob(lines, tmpvar, true);
                }
            }

            @Override
            public CJJSBlob visitIs(CJIRIs e, Void a) {
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                if (left.isSimple() && right.isSimple()) {
                    return CJJSBlob.inline("(" + left.getExpression() + "===" + right.getExpression() + ")", false);
                } else {
                    left = left.toPure(ctx);
                    var lines = left.getLines();
                    lines.addAll(right.getLines());
                    return new CJJSBlob(lines, "(" + left.getExpression() + "===" + right.getExpression() + ")", false);
                }
            }

            @Override
            public CJJSBlob visitNullWrap(CJIRNullWrap e, Void a) {
                return e.getInner().map(i -> translateExpression(i)).getOrElseDo(() -> CJJSBlob.inline("null", true));
            }

            @Override
            public CJJSBlob visitListDisplay(CJIRListDisplay e, Void a) {
                return handleList(e.getExpressions());
            }

            @Override
            public CJJSBlob visitTupleDisplay(CJIRTupleDisplay e, Void a) {
                return handleList(e.getExpressions());
            }

            private CJJSBlob handleList(List<CJIRExpression> expressions) {
                var lines = List.<String>of();
                var args = expressions.map(arg -> translateExpression(arg));
                if (!args.all(arg -> arg.isSimple())) {
                    args = args.map(arg -> arg.toPure(ctx));
                }
                var out = List.<String>of();
                for (var blob : args) {
                    lines.addAll(blob.getLines());
                    out.add(blob.getExpression());
                }
                return new CJJSBlob(lines, "[" + Str.join(",", out) + "]", false);
            }

            @Override
            public CJJSBlob visitIf(CJIRIf e, Void a) {
                var condition = translateExpression(e.getCondition());
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                if (condition.isSimple() && left.isSimple() && right.isSimple()) {
                    return CJJSBlob.inline("(" + condition.getExpression() + "?" + left.getExpression() + ":"
                            + right.getExpression() + ")", false);
                } else {
                    var tmpvar = ctx.newTempVarName();
                    var lines = List.of("let " + tmpvar + ";\n");
                    lines.addAll(condition.getLines());
                    lines.add("if(" + condition.getExpression() + "){\n");
                    lines.addAll(left.getLines());
                    lines.add(tmpvar + "=" + left.getExpression() + ";\n");
                    lines.add("}else{\n");
                    lines.addAll(right.getLines());
                    lines.add(tmpvar + "=" + right.getExpression() + ";\n");
                    lines.add("}\n");
                    return new CJJSBlob(lines, tmpvar, true);
                }
            }

            @Override
            public CJJSBlob visitIfNull(CJIRIfNull e, Void a) {
                var inner = translateExpression(e.getExpression()).toPure(ctx);
                var target = translateTarget(e.getTarget());
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                var tmpvar = ctx.newTempVarName();
                var lines = List.of("let " + tmpvar + ";\n");
                lines.addAll(inner.getLines());
                lines.add("if((" + inner.getExpression() + ")!==null){\n");
                lines.add("let " + target + "=" + inner.getExpression() + ";\n");
                lines.addAll(left.getLines());
                lines.add(tmpvar + "=" + left.getExpression() + ";\n");
                lines.add("}else{\n");
                lines.addAll(right.getLines());
                lines.add(tmpvar + "=" + right.getExpression() + ";\n");
                lines.add("}\n");
                return new CJJSBlob(lines, tmpvar, true);
            }

            @Override
            public CJJSBlob visitWhile(CJIRWhile e, Void a) {
                var condition = translateExpression(e.getCondition());
                var lines = List.<String>of();
                if (condition.isSimple()) {
                    lines.add("while(" + condition.getExpression() + "){\n");
                } else {
                    lines.add("while(true){\n");
                    lines.addAll(condition.getLines());
                    lines.add("if(!(" + condition.getExpression() + "))break;\n");
                }
                translateExpression(e.getBody()).dropValue(lines);
                lines.add("}\n");
                return new CJJSBlob(lines, "undefined", true);
            }

            @Override
            public CJJSBlob visitFor(CJIRFor e, Void a) {
                var iterator = translateExpression(e.getIterator());
                var lines = iterator.getLines();
                var target = translateTarget(e.getTarget());
                lines.add("for (const " + target + " of " + iterator.getExpression() + "){\n");
                var body = translateExpression(e.getBody());
                body.dropValue(lines);
                lines.add("}\n");
                return new CJJSBlob(lines, "undefined", true);
            }

            @Override
            public CJJSBlob visitWhen(CJIRWhen e, Void a) {
                var target = translateExpression(e.getTarget()).toPure(ctx);
                var lines = target.getLines();
                var tmpvar = ctx.newTempVarName();
                lines.add("let " + tmpvar + ";\n");
                if (e.getTarget().getType().isSimpleUnion()) {
                    lines.add("switch(" + target.getExpression() + "){\n");
                } else {
                    lines.add("switch((" + target.getExpression() + ")[0]){\n");
                }
                for (var entry : e.getCases()) {
                    var caseDefn = entry.get2();
                    var body = translateExpression(entry.get5());
                    var tag = caseDefn.getTag();
                    var names = entry.get3().map(d -> translateLocalVariableName(d.getName()));
                    var mutable = entry.get3().any(d -> d.isMutable());
                    var prefix = mutable ? "let " : "const ";
                    lines.add("case " + tag + ":{\n");
                    if (!e.getTarget().getType().isSimpleUnion()) {
                        lines.add(prefix + "[," + Str.join(",", names) + "]=" + target.getExpression() + ";\n");
                    }
                    body.setValue(lines, tmpvar + "=");
                    lines.add("break;\n");
                    lines.add("}\n");
                }
                if (e.getFallback().isPresent()) {
                    var fallback = translateExpression(e.getFallback().get());
                    lines.add("default:{\n");
                    fallback.setValue(lines, tmpvar + "=");
                    lines.add("}\n");
                } else {
                    lines.add("default:throw new Error(\"Invalid tag\");\n");
                }
                lines.add("}\n");
                return new CJJSBlob(lines, tmpvar, true);
            }

            @Override
            public CJJSBlob visitSwitch(CJIRSwitch e, Void a) {
                var target = translateExpression(e.getTarget());
                var lines = target.getLines();
                var tmpvar = ctx.newTempVarName();
                lines.add("let " + tmpvar + ";\n");
                lines.add("switch(" + target.getExpression() + "){\n");
                for (var case_ : e.getCases()) {
                    var values = case_.get1().map(c -> {
                        var v = translateExpression(c);
                        // TODO: Reconsider this restriction
                        // At the very least, a check like this should live in one of the JSPass*
                        // classees and not in code generation.
                        if (!v.isSimple()) {
                            throw CJError.of("Only simple expressions are allowed here", c.getMark());
                        }
                        return v;
                    });
                    for (var value : values) {
                        lines.add("case " + value.getExpression() + ":\n");
                    }
                    lines.add("{\n");
                    var body = translateExpression(case_.get2());
                    lines.addAll(body.getLines());
                    lines.add(tmpvar + "=" + body.getExpression() + ";\n");
                    lines.add("break;\n");
                    lines.add("}\n");
                }
                lines.add("default:");
                if (e.getFallback().isPresent()) {
                    lines.add("{\n");
                    var fallback = translateExpression(e.getFallback().get());
                    lines.addAll(fallback.getLines());
                    lines.add(tmpvar + "=" + fallback.getExpression() + ";\n");
                    lines.add("}\n");
                } else {
                    lines.add("throw new Error('Unhandled switch case');\n");
                }
                lines.add("}\n");
                return new CJJSBlob(lines, tmpvar, true);
            }

            @Override
            public CJJSBlob visitLambda(CJIRLambda e, Void a) {
                var parameters = e.getParameters();
                var parameterNames = parameters.map(p -> translateLocalVariableName(p.getName()));
                var paramstr = "(" + Str.join(",", parameterNames) + ")=>";
                var blob = translateExpression(e.getBody());
                if (blob.isSimple()) {
                    return new CJJSBlob(List.of(), paramstr + "(" + blob.getExpression() + ")", false);
                } else {
                    var lines = List.of("{\n");
                    if (e.getReturnType().isUnitType()) {
                        blob.dropValue(lines);
                    } else {
                        blob.setValue(lines, "return ");
                    }
                    lines.add("}\n");
                    var body = Str.join("", lines);
                    return new CJJSBlob(List.of(), "(" + paramstr + body + ")", false);
                }
            }

            @Override
            public CJJSBlob visitReturn(CJIRReturn e, Void a) {
                var inner = translateExpression(e.getExpression());
                var lines = inner.getLines();
                lines.add("return " + inner.getExpression() + ";\n");
                return new CJJSBlob(lines, "NORETURN", true);
            }

            @Override
            public CJJSBlob visitAwait(CJIRAwait e, Void a) {
                var inner = translateExpression(e.getInner());
                return new CJJSBlob(inner.getLines(), "(await " + inner.getExpression() + ")", false);
            }

            @Override
            public CJJSBlob visitThrow(CJIRThrow e, Void a) {
                var inner = translateExpression(e.getExpression());
                var lines = inner.getLines();
                var type = translateType(e.getExpression().getType());
                lines.add("throw [" + inner.getExpression() + "," + type + "];\n");
                return new CJJSBlob(lines, "undefined", true);
            }

            @Override
            public CJJSBlob visitTry(CJIRTry e, Void a) {
                var tmpvar = ctx.newTempVarName();
                var lines = List.of("let " + tmpvar + ";\n");
                lines.add("try{\n");
                var body = translateExpression(e.getBody());
                lines.addAll(body.getLines());
                lines.add(tmpvar + "=" + body.getExpression() + ";\n");
                if (e.getClauses().size() > 0) {
                    lines.add("}catch(p){if(!Array.isArray(p))throw p;const [e,t]=p;\n");
                    for (int i = 0; i < e.getClauses().size(); i++) {
                        var clause = e.getClauses().get(i);
                        lines.add((i == 0 ? "if" : "else if") + "(typeEq(t," + translateType(clause.get2()) + ")){\n");
                        lines.add("const " + translateTarget(clause.get1()) + "=e;\n");
                        var clauseBody = translateExpression(clause.get3());
                        lines.addAll(clauseBody.getLines());
                        lines.add(tmpvar + "=" + clauseBody.getExpression() + ";\n");
                        lines.add("}\n");
                    }
                    lines.add("else{throw p;}\n");
                }
                lines.add("}\n");
                if (e.getFin().isPresent()) {
                    lines.add("finally{\n");
                    lines.addAll(translateExpression(e.getFin().get()).toPure(ctx).getLines());
                    lines.add("}\n");
                }
                return new CJJSBlob(lines, tmpvar, true);
            }
        }, null);
    }
}