package crossj.cj;

import crossj.base.List;
import crossj.base.Str;

public final class CJJSTranslator {
    private final CJJSContext ctx;
    private final CJIRItem currentItem;

    CJJSTranslator(CJJSContext ctx, CJIRItem currentItem) {
        this.ctx = ctx;
        this.currentItem = currentItem;
    }

    private String translateMethodName(String methodName) {
        return "M$" + methodName;
    }

    private String translateItemMetaClassName(String itemName) {
        return "MC$" + itemName;
    }

    private String translateItemMetaObjectName(String itemName) {
        return "MO$" + itemName;
    }

    private String translateMethodLevelTypeVariable(String variableName) {
        return "TV$" + variableName;
    }

    private String translateTraitLevelTypeVariableName(String variableName) {
        return "TV$" + currentItem.getFullName().replace(".", "$") + "$" + variableName;
    }

    private String translateItemLevelTypeVariable(String variableName) {
        if (currentItem.isTrait()) {
            return "this." + translateTraitLevelTypeVariableName(variableName) + "()";
        } else {
            return translateMethodLevelTypeVariable(variableName);
        }
    }

    CJJSBlob translateExpression(CJIRExpression expression) {
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
                lines.add("{");
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    var blob = translateExpression(exprs.get(i));
                    lines.addAll(blob.getLines());
                    if (!blob.isPure()) {
                        lines.add(blob.getExpression() + ";");
                    }
                }
                var last = translateExpression(exprs.last());
                lines.addAll(last.getLines());
                if (returns) {
                    lines.add(tmpvar + "=" + last.getExpression());
                } else if (!last.isPure()) {
                    lines.add(last.getExpression());
                }
                lines.add("}");
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

    String translateType(CJIRType type) {
        return type.accept(new CJIRTypeVisitor<String, Void>() {

            @Override
            public String visitClass(CJIRClassType t, Void a) {
                if (t.getArgs().isEmpty()) {
                    return translateItemMetaObjectName(t.getItem().getFullName());
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
