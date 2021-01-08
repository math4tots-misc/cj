package crossj.cj;

import crossj.base.FS;
import crossj.base.Func1;
import crossj.base.IO;
import crossj.base.List;
import crossj.base.Pair;
import crossj.base.Range;
import crossj.base.Set;
import crossj.base.Str;

public final class CJJSTranslator {
    private static final String jsroot = FS.join("src", "main", "resources", "js");
    private final StringBuilder out;
    private final CJJSContext ctx;
    private final CJIRItem item;
    private final CJIRClassType selfType;

    public static String translate(CJIRContext irctx, CJIRRunMode runMode) {
        var out = new StringBuilder();
        var jsctx = new CJJSContext();
        out.append("(function(){\n");
        out.append("\"use strict\"\n");
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
        return out.toString();
    }

    private static void emitPrelude(StringBuilder out) {
        var path = FS.join(jsroot, "prelude.js");
        out.append(IO.readFile(path));
    }

    private static void translateItems(StringBuilder out, CJIRContext irctx, CJJSContext jsctx) {
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
            if (!item.isTrait() && item.getTypeParameters().isEmpty()) {
                var itemName = item.getFullName();
                out.append("const " + translateItemMetaObjectName(itemName) + "=new "
                        + translateItemMetaClassName(itemName) + "();\n");
            }
        }
    }

    private static void addTypeVariableMethods(StringBuilder out, CJJSContext jsctx, CJIRItem item) {
        var itemMetaClassName = translateItemMetaClassName(item.getFullName());
        var translator = new CJJSTranslator(out, jsctx, item);
        walkTraits(item, trait -> {
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

    private static void inheritMethods(StringBuilder out, CJIRItem item) {
        var itemMetaClassName = translateItemMetaClassName(item.getFullName());
        var seenMethods = Set.fromIterable(item.getMethods().map(m -> m.getName()));
        walkTraits(item, trait -> {
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

    private static void walkTraits(CJIRItem item, Func1<Void, CJIRTrait> f) {
        CJIRContextBase.walkTraits(item, f);
    }

    private static void translateItem(StringBuilder out, CJJSContext ctx, CJIRItem item) {
        new CJJSTranslator(out, ctx, item).emitItem();
    }

    CJJSTranslator(StringBuilder out, CJJSContext ctx, CJIRItem item) {
        this.out = out;
        this.ctx = ctx;
        this.item = item;
        if (item.isTrait()) {
            selfType = null;
        } else {
            selfType = new CJIRClassType(item, item.getTypeParameters().map(tp -> new CJIRVariableType(tp, List.of())));
        }
    }

    private static String translateMethodName(String methodName) {
        return "M$" + methodName;
    }

    private static String translateItemMetaClassName(String itemName) {
        return "MC$" + itemName.replace(".", "$");
    }

    private static String translateItemMetaObjectName(String itemName) {
        return "MO$" + itemName.replace(".", "$");
    }

    private static String translateMethodLevelTypeVariable(String variableName) {
        return "TV$" + variableName;
    }

    private String translateTraitLevelTypeVariableName(String variableName) {
        return translateTraitLevelTypeVariableNameWithTraitName(item.getFullName(), variableName);
    }

    private static String translateTraitLevelTypeVariableNameWithTraitName(String traitName, String variableName) {
        return "TV$" + traitName.replace(".", "$") + "$" + variableName;
    }

    private static String translateLocalVariableName(String variableName) {
        return "L$" + variableName;
    }

    private static String translateFieldName(String fieldName) {
        return "F$" + fieldName;
    }

    private String translateItemLevelTypeVariable(String variableName) {
        return item.isTrait() ? "this." + translateTraitLevelTypeVariableName(variableName) + "()"
                : "this." + translateMethodLevelTypeVariable(variableName);
    }

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
            var blob = translateExpression(field.getExpression().get());
            blob.getLines().forEach(out::append);
            out.append("this." + fieldName + "=" + blob.getExpression() + ";\n");
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
            for (var field : nonStaticFields) {
                var index = field.getIndex();
                var getterMethodName = translateMethodName(field.getGetterName());
                out.append(getterMethodName + "(a){return a[" + index + "]}\n");
                if (field.isMutable()) {
                    var setterMethodName = translateMethodName(field.getSetterName());
                    out.append(setterMethodName + "(a,x){a[" + index + "]=x}\n");
                }
            }
            var mallocMethodName = translateMethodName("__malloc");
            if (nonStaticFields.isEmpty()) {
                out.append(mallocMethodName + "(){return null;}\n");
            } else {
                var argnames = Str.join(",", Range.upto(nonStaticFields.size()).map(i -> "a" + i));
                out.append(mallocMethodName + "(" + argnames + "){return [" + argnames + "]}\n");
            }
        }

        // for unions: emit case constructors
        if (item.getKind() == CJIRItemKind.Union && !item.isNative()) {
            for (var caseDefn : item.getCases()) {
                var methodName = translateMethodName(caseDefn.getName());
                var argc = caseDefn.getTypes().size();
                var args = Str.join(",", Range.upto(argc).map(i -> "a" + i));
                out.append(methodName + "(" + args + "){return[" + caseDefn.getTag() + "," + args + "];}\n");
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
                        return CJJSBlob.inline("null", true);
                    case Bool:
                        return CJJSBlob.inline(e.getRawText(), true);
                    case Char:
                        switch (e.getRawText()) {
                            case "'\\''":
                                return CJJSBlob.inline("" + (int) '\'', true);
                            case "'\\\"'":
                                return CJJSBlob.inline("" + (int) '"', true);
                            case "'\\\\'":
                                return CJJSBlob.inline("" + (int) '\\', true);
                            case "'\\n'":
                                return CJJSBlob.inline("" + (int) '\n', true);
                            case "'\\t'":
                                return CJJSBlob.inline("" + (int) '\t', true);
                            case "'\\r'":
                                return CJJSBlob.inline("" + (int) '\r', true);
                            case "'\\0'":
                                return CJJSBlob.inline("" + (int) '\0', true);
                        }
                        if (e.getRawText().length() == 3 && e.getRawText().charAt(0) == '\''
                                && e.getRawText().charAt(2) == '\'') {
                            return CJJSBlob.inline("" + (int) e.getRawText().charAt(1), true);
                        }
                        return CJJSBlob.inline(e.getRawText() + ".codePointAt(0)", true);
                    case Int:
                        return CJJSBlob.inline(e.getRawText(), true);
                    case Double:
                        return CJJSBlob.inline(e.getRawText(), true);
                    case String:
                        return CJJSBlob.inline(e.getRawText(), true);
                }
                throw CJError.of("TODO: " + e.getKind(), e.getMark());
            }

            @Override
            public CJJSBlob visitBlock(CJIRBlock e, Void a) {
                var exprs = e.getExpressions();
                var returns = !e.getType().isUnionType();
                var tmpvar = returns ? ctx.newTempVarName() : "null";
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
                var typeArgs = e.getTypeArgs().map(CJJSTranslator.this::translateType);
                var args = e.getArgs().map(CJJSTranslator.this::translateExpression);
                args = args.all(arg -> arg.isSimple()) ? args : args.map(arg -> arg.toPure(ctx));
                var lines = List.<String>of();
                for (var arg : args) {
                    lines.addAll(arg.getLines());
                }
                var allArgs = List.of(typeArgs, args.map(arg -> arg.getExpression())).flatMap(x -> x);
                var pair = joinMethodCall(e.getOwner(), e.getMethodRef(), allArgs);
                return new CJJSBlob(lines, pair.get1(), pair.get2());
            }

            private Pair<String, Boolean> joinMethodCall(CJIRType owner, CJIRMethodRef methodRef,
                    List<String> allArgs) {
                var fullMethodName = methodRef.getOwner().getItem().getFullName() + "." + methodRef.getName();
                switch (fullMethodName) {
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
                    case "cj.Fn0":
                    case "cj.Fn1":
                    case "cj.Fn2":
                    case "cj.Fn3":
                    case "cj.Fn4":
                        return Pair.of(allArgs.get(0) + "(" + Str.join(",", allArgs.sliceFrom(1)) + ")", false);
                    default:
                        return Pair.of(translateType(owner) + "." + translateMethodName(methodRef.getName()) + "("
                                + Str.join(",", allArgs) + ")", false);
                }
            }

            @Override
            public CJJSBlob visitVariableDeclaration(CJIRVariableDeclaration e, Void a) {
                var prefix = e.isMutable() ? "let " : "const ";
                var inner = translateExpression(e.getExpression());
                var lines = inner.getLines();
                lines.add(prefix + translateTarget(e.getTarget()) + "=" + inner.getExpression() + ";\n");
                return new CJJSBlob(lines, "null", true);
            }

            @Override
            public CJJSBlob visitVariableAccess(CJIRVariableAccess e, Void a) {
                return CJJSBlob.inline(translateLocalVariableName(e.getDeclaration().getName()), true);
            }

            @Override
            public CJJSBlob visitAssignment(CJIRAssignment e, Void a) {
                var expr = translateExpression(e.getExpression());
                var target = translateTarget(e.getTarget());
                var lines = expr.getLines();
                lines.add(target + "=" + expr.getExpression() + ";\n");
                return new CJJSBlob(lines, "null", true);
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
            public CJJSBlob visitListDisplay(CJIRListDisplay e, Void a) {
                var lines = List.<String>of();
                var args = e.getExpressions().map(arg -> translateExpression(arg));
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
            public CJJSBlob visitWhile(CJIRWhile e, Void a) {
                var condition = translateExpression(e.getCondition());
                var lines = condition.getLines();
                lines.add("while(" + condition.getExpression() + "){\n");
                translateExpression(e.getBody()).dropValue(lines);
                lines.add("}\n");
                return new CJJSBlob(lines, "null", true);
            }

            @Override
            public CJJSBlob visitUnion(CJIRUnion e, Void a) {
                var target = translateExpression(e.getTarget()).toPure(ctx);
                var lines = target.getLines();
                var tmpvar = ctx.newTempVarName();
                lines.add("let " + tmpvar + ";\n");
                lines.add("switch((" + target.getExpression() + ")[0]){\n");
                for (var entry : e.getCases()) {
                    var caseDefn = entry.get2();
                    var body = translateExpression(entry.get4());
                    var tag = caseDefn.getTag();
                    var names = entry.get3().map(d -> translateLocalVariableName(d.getName()));
                    var mutable = entry.get3().any(d -> d.isMutable());
                    var prefix = mutable ? "let " : "const ";
                    lines.add("case " + tag + ":{\n");
                    lines.add(prefix + "[," + Str.join(",", names) + "]=" + target.getExpression() + ";\n");
                    body.setValue(lines, tmpvar + "=");
                    lines.add("break;\n");
                    lines.add("}\n");
                }
                if (e.getFallback().isPresent()) {
                    var fallback = translateExpression(e.getFallback().get());
                    lines.add("default:{\n");
                    fallback.dropValue(lines);
                    lines.add("}\n");
                } else {
                    lines.add("default:throw new Error(\"Invalid tag\");\n");
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
            public CJJSBlob visitAwait(CJIRAwait e, Void a) {
                var inner = translateExpression(e.getInner());
                return new CJJSBlob(inner.getLines(), "(await " + inner.getExpression() + ")", false);
            }
        }, null);
    }

    private String translateType(CJIRType type) {
        return type.accept(new CJIRTypeVisitor<String, Void>() {

            @Override
            public String visitClass(CJIRClassType t, Void a) {
                if (t.getArgs().isEmpty()) {
                    return translateItemMetaObjectName(t.getItem().getFullName());
                } else if (selfType != null && selfType.equals(t)) {
                    return "this";
                } else {
                    var metaClassName = translateItemMetaClassName(t.getItem().getFullName());
                    var args = Str.join(",", t.getArgs().map(arg -> translateType(arg)));
                    return "new " + metaClassName + "(" + args + ")";
                }
            }

            @Override
            public String visitVariable(CJIRVariableType t, Void a) {
                if (t.isMethodLevel()) {
                    return translateMethodLevelTypeVariable(t.getName());
                } else {
                    return translateItemLevelTypeVariable(t.getName());
                }
            }

            @Override
            public String visitSelf(CJIRSelfType t, Void a) {
                return "this";
            }
        }, null);
    }

    private String translateTarget(CJIRAssignmentTarget target) {
        return target.accept(new CJIRAssignmentTargetVisitor<String, Void>() {

            @Override
            public String visitName(CJIRNameAssignmentTarget t, Void a) {
                return translateLocalVariableName(t.getName());
            }
        }, null);
    }
}
