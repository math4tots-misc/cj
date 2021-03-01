package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Str;

public abstract class CJJSTranslatorBase {
    final CJJSSink out;
    final CJJSContext ctx;
    final CJIRItem item;
    final CJIRClassType selfType;

    CJJSTranslatorBase(CJJSSink out, CJJSContext ctx, CJIRItem item, CJIRClassType selfType) {
        this.out = out;
        this.ctx = ctx;
        this.item = item;
        this.selfType = selfType;
    }

    static String translateMethodName(String methodName) {
        return "M$" + methodName;
    }

    static String translateItemMetaClassName(String itemName) {
        return "MC$" + itemName.replace(".", "$");
    }

    static String translateItemMetaObjectName(String itemName) {
        return "MO$" + itemName.replace(".", "$");
    }

    static String translateMethodLevelTypeVariable(String variableName) {
        return "TV$" + variableName;
    }

    String translateTraitLevelTypeVariableName(String variableName) {
        return translateTraitLevelTypeVariableNameWithTraitName(item.getFullName(), variableName);
    }

    static String translateTraitLevelTypeVariableNameWithTraitName(String traitName, String variableName) {
        return "TV$" + traitName.replace(".", "$") + "$" + variableName;
    }

    String translateItemLevelTypeVariable(String variableName) {
        return item.isTrait() ? "this." + translateTraitLevelTypeVariableName(variableName) + "()"
                : "this." + translateMethodLevelTypeVariable(variableName);
    }

    static String translateLocalVariableName(String variableName) {
        return "L$" + variableName;
    }

    static String translateFieldName(String fieldName) {
        return "F$" + fieldName;
    }

    String translateType(CJIRType type) {
        return type.accept(new CJIRTypeVisitor<String, Void>() {

            @Override
            public String visitClass(CJIRClassType t, Void a) {
                if (t.getArgs().isEmpty()) {
                    return translateItemMetaObjectName(t.getItem().getFullName());
                } else if (selfType != null && selfType.equals(t)) {
                    return "this";
                } else {
                    var args = translateTypeArgs(t.getItem().getTypeParameters(), t.getArgs());
                    if (args.all("null"::equals)) {
                        return translateItemMetaObjectName(t.getItem().getFullName());
                    } else {
                        var metaClassName = translateItemMetaClassName(t.getItem().getFullName());
                        return "new " + metaClassName + "(" + Str.join(",", args) + ")";
                    }
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

    List<String> translateTypeArgs(List<CJIRTypeParameter> parameters, List<CJIRType> args) {
        Assert.equals(parameters.size(), args.size());
        var out = List.<String>of();
        for (int i = 0; i < args.size(); i++) {
            if (parameters.get(i).isGeneric()) {
                out.add("null");
            } else {
                out.add(translateType(args.get(i)));
            }
        }
        return out;
    }

    String translateTarget(CJIRAssignmentTarget target) {
        return target.accept(new CJIRAssignmentTargetVisitor<String, Void>() {

            @Override
            public String visitName(CJIRNameAssignmentTarget t, Void a) {
                return translateLocalVariableName(t.getName());
            }

            @Override
            public String visitTuple(CJIRTupleAssignmentTarget t, Void a) {
                return "[" + Str.join(",", t.getSubtargets().map(s -> translateTarget(s))) + "]";
            }
        }, null);
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

    static boolean isWrapperType(CJIRType type) {
        if (!(type instanceof CJIRClassType)) {
            return false;
        }
        var item = ((CJIRClassType) type).getItem();
        return isWrapperItem(item);
    }

    String toVariableOrLiteral(String expression) {
        if (isVariableOrLiteral(expression)) {
            return expression;
        } else {
            var tmpvar = ctx.newTempVarName();
            out.append("const " + tmpvar + "=" + expression + ";\n");
            Assert.that(isVariableOrLiteral(tmpvar));
            return tmpvar;
        }
    }

    boolean isVariableOrLiteral(String expression) {
        if (expression.length() > 30) {
            return false;
        }
        if (isStringLiteral(expression)) {
            return true;
        }
        var chars = Str.chars(expression);
        if (expression.startsWith("0x") && chars.sliceFrom(2).all(c -> isDigit(c))) {
            // hex literal
            return true;
        }
        return chars.all(c -> isDigit(c) || c == '.') || chars.all(c -> isWord(c));
    }

    private boolean isStringLiteral(String expression) {
        if (expression.length() < 2) {
            return false;
        }
        if (!expression.startsWith("\"") || !expression.endsWith("\"")) {
            return false;
        }
        var inner = expression.substring(1, expression.length() - 1).replace("\\\"", "");
        return !inner.contains("\"");
    }

    private boolean isDigit(int c) {
        return c >= '0' && c <= '9';
    }

    private boolean isWord(int c) {
        return isDigit(c) || c == '_' || c == '$' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z';
    }
}
