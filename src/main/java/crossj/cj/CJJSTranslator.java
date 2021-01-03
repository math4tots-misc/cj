package crossj.cj;

import crossj.base.FS;
import crossj.base.IO;
import crossj.base.List;
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
        runMode.accept(new CJIRRunModeVisitor<Void, Void>(){
            @Override
            public Void visitMain(CJIRRunModeMain m, Void a) {
                var mainClass = translateItemMetaObjectName(m.getMainClass());
                out.append(mainClass + "." + translateMethodName("main") + "();\n");
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

    private String translateMethodLevelTypeVariable(String variableName) {
        return "TV$" + variableName;
    }

    private String translateTraitLevelTypeVariableName(String variableName) {
        return "TV$" + item.getFullName().replace(".", "$") + "$" + variableName;
    }

    private String translateLocalVariableName(String variableName) {
        return "L$" + variableName;
    }

    private String translateItemLevelTypeVariable(String variableName) {
        if (item.isTrait()) {
            return "this." + translateTraitLevelTypeVariableName(variableName) + "()";
        } else {
            return translateMethodLevelTypeVariable(variableName);
        }
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
        for (var member : item.getMembers()) {
            if (member instanceof CJIRMethod) {
                var method = (CJIRMethod) member;
                if (method.getBody().isPresent()) {
                    var methodName = translateMethodName(method.getName());
                    var typeArgNames = method.getTypeParameters()
                            .map(p -> translateMethodLevelTypeVariable(p.getName()));
                    var argNames = method.getParameters().map(p -> translateLocalVariableName(p.getName()));
                    var allArgNames = List.of(typeArgNames, argNames).flatMap(x -> x);
                    out.append(methodName + "(" + Str.join(",", allArgNames) + "){\n");
                    var body = translateExpression(method.getBody().get());
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
                var returns = !e.getType().toString().equals("cj.Unit");
                var tmpvar = returns ? ctx.newTempVarName() : "";
                var lines = List.of(returns ? "let " + tmpvar + ";" : "");
                lines.add("{\n");
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    var blob = translateExpression(exprs.get(i));
                    lines.addAll(blob.getLines());
                    if (!blob.isPure()) {
                        lines.add(blob.getExpression() + ";\n");
                    }
                }
                var last = translateExpression(exprs.last());
                lines.addAll(last.getLines());
                if (returns) {
                    lines.add(tmpvar + "=" + last.getExpression() + ";\n");
                } else if (!last.isPure()) {
                    lines.add(last.getExpression() + ";\n");
                }
                lines.add("}\n");
                return new CJJSBlob(lines, tmpvar, true);
            }

            @Override
            public CJJSBlob visitMethodCall(CJIRMethodCall e, Void a) {
                var owner = translateType(e.getOwner());
                var typeArgs = e.getTypeArgs().map(CJJSTranslator.this::translateType);
                var args = e.getArgs().map(CJJSTranslator.this::translateExpression);
                var methodName = translateMethodName(e.getName());
                if (args.all(arg -> arg.isSimple())) {
                    var allArgs = List.of(typeArgs, args.map(arg -> arg.getExpression())).flatMap(x -> x);
                    return CJJSBlob.inline(owner + "." + methodName + "(" + Str.join(",", allArgs) + ")", false);
                } else {
                    args = args.map(arg -> arg.toPure(ctx));
                    var lines = List.<String>of();
                    for (var arg : args) {
                        lines.addAll(arg.getLines());
                    }
                    var allArgs = List.of(typeArgs, args.map(arg -> arg.getExpression())).flatMap(x -> x);
                    return new CJJSBlob(lines, owner + "." + methodName + "(" + Str.join(",", allArgs) + ")", false);
                }
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
        }, null);
    }
}
