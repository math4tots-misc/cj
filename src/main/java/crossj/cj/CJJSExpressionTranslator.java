package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Str;

/**
 * TODO: Actually complete this, or delete this...
 */
public final class CJJSExpressionTranslator extends CJJSTranslatorBase {
    CJJSExpressionTranslator(StringBuilder out, CJJSContext ctx, CJIRItem item, CJIRClassType selfType) {
        super(out, ctx, item, selfType);
    }

    String translateExpressionToVariableOrLiteral(CJIRExpression expression) {
        return toVariableOrLiteral(translateExpression(expression));
    }

    String translateExpression(CJIRExpression expression) {
        return expression.accept(new CJIRExpressionVisitor<String, Void>() {

            @Override
            public String visitLiteral(CJIRLiteral e, Void a) {
                switch (e.getKind()) {
                    case Unit:
                        return "undefined";
                    case Char:
                        return "" + CJToken.charLiteralToInt(e.getRawText(), e.getMark());
                    case Bool:
                    case Int:
                    case Double:
                    case String:
                    case BigInt:
                        return e.getRawText();
                }
                throw CJError.of("TODO: " + e.getKind(), e.getMark());
            }

            @Override
            public String visitBlock(CJIRBlock e, Void a) {
                var exprs = e.getExpressions();
                var tmpvar = ctx.newTempVarName();
                out.append("let " + tmpvar + ";{\n");
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    translateExpression(exprs.get(i));
                }
                var last = translateExpression(exprs.last());
                out.append(tmpvar + "=" + last + ";\n");
                out.append("}\n");
                return tmpvar;
            }

            @Override
            public String visitMethodCall(CJIRMethodCall e, Void a) {
                var typeArgs = e.getMethodRef().isGeneric() ? e.getTypeArgs().map(i -> "null")
                        : translateTypeArgs(e.getMethodRef().getMethod().getTypeParameters(), e.getTypeArgs());
                var args = e.getArgs().map(CJJSExpressionTranslator.this::translateExpression);
                var allArgs = List.of(typeArgs, args).flatMap(x -> x);
                return emitMethodCall(e.getMark(), e.getOwner(), e.getMethodRef(), allArgs);
            }

            private String emitMethodCall(CJMark mark, CJIRType owner, CJIRMethodRef methodRef, List<String> allArgs) {
                var fullMethodName = methodRef.getOwner().getItem().getFullName() + "." + methodRef.getName();
                switch (fullMethodName) {
                    case "cj.Int.__add":
                        return "((" + Str.join("+", allArgs) + ")|0)";
                    case "cj.Int.__mul":
                        return "((" + Str.join("*", allArgs) + ")|0)";
                    case "cj.Int.__sub":
                        return "((" + Str.join("-", allArgs) + ")|0)";
                    case "cj.Int.__truncdiv":
                        return "((" + Str.join("/", allArgs) + ")|0)";
                    case "cj.Int.__div":
                        return "(" + Str.join("/", allArgs) + ")";
                    case "cj.Double.__add":
                        return "(" + Str.join("+", allArgs) + ")";
                    case "cj.Double.__mul":
                        return "(" + Str.join("*", allArgs) + ")";
                    case "cj.Double.__sub":
                        return "(" + Str.join("-", allArgs) + ")";
                    case "cj.Double.__truncdiv":
                        return "((" + Str.join("/", allArgs) + ")|0)";
                    case "cj.Double.__div":
                        return "(" + Str.join("/", allArgs) + ")";
                    case "cj.List.empty":
                    case "cj.List_.empty":
                        return "[]";
                    case "cj.Fn0":
                    case "cj.Fn1":
                    case "cj.Fn2":
                    case "cj.Fn3":
                    case "cj.Fn4": {
                        if (ctx.isStackEnabled()) {
                            out.append("stack.push(" + ctx.addMark(mark) + ");\n");
                        }
                        var outvar = ctx.newTempVarName();
                        out.append("const " + outvar + "=" + allArgs.get(0) + "(" + Str.join(",", allArgs.sliceFrom(1))
                                + ");\n");
                        if (ctx.isStackEnabled()) {
                            out.append("stack.pop();\n");
                        }
                        return outvar;
                    }
                    default: {
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
                                    case "=":
                                        Assert.equals(allArgs.size(), 1);
                                        out.append(target + info.getKind() + allArgs.last() + ";\n");
                                        return "undefined";
                                    case "+=":
                                        Assert.equals(allArgs.size(), 1);
                                        out.append(target + "=(" + ownerStr + "."
                                                + translateMethodName(field.getGetterName()) + "())" + "+"
                                                + allArgs.last() + ";\n");
                                        return "undefined";
                                }
                            } else if (!field.isStatic()) {
                                var target = isWrapperType(owner) ? allArgs.get(0)
                                        : allArgs.get(0) + "[" + field.getIndex() + "]";
                                switch (info.getKind()) {
                                    case "":
                                        Assert.equals(allArgs.size(), 1);
                                        return target;
                                    case "=":
                                    case "+=":
                                        Assert.equals(allArgs.size(), 2);
                                        Assert.that(field.isMutable());
                                        out.append(target + info.getKind() + allArgs.last() + ";\n");
                                        return "undefined";
                                }
                            }
                        }

                        if (ctx.isStackEnabled()) {
                            out.append("stack.push(" + ctx.addMark(mark) + ");\n");
                        }
                        var outvar = ctx.newTempVarName();
                        out.append("const " + outvar + "=" + ownerStr + "." + translateMethodName(methodRef.getName())
                                + "(" + Str.join(",", allArgs) + ");\n");
                        if (ctx.isStackEnabled()) {
                            out.append("stack.pop();\n");
                        }
                        return outvar;
                    }
                }
            }

            @Override
            public String visitVariableDeclaration(CJIRVariableDeclaration e, Void a) {
                var prefix = e.isMutable() ? "let " : "const ";
                var inner = translateExpression(e.getExpression());
                out.append(prefix + translateTarget(e.getTarget()) + "=" + inner + ";\n");
                return "undefined";
            }

            @Override
            public String visitVariableAccess(CJIRVariableAccess e, Void a) {
                return translateLocalVariableName(e.getDeclaration().getName());
            }

            @Override
            public String visitAssignment(CJIRAssignment e, Void a) {
                var expr = translateExpression(e.getExpression());
                var target = translateTarget(e.getTarget());
                out.append(target + "=" + expr + ";\n");
                return "undefined";
            }

            @Override
            public String visitAugmentedAssignment(CJIRAugmentedAssignment e, Void a) {
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
                out.append(target + op + augexpr + ";\n");
                return null;
            }

            @Override
            public String visitLogicalNot(CJIRLogicalNot e, Void a) {
                var inner = translateExpression(e.getInner());
                return "(!" + inner + ")";
            }

            @Override
            public String visitLogicalBinop(CJIRLogicalBinop e, Void a) {
                var tmpvar = ctx.newTempVarName();
                out.append("let " + tmpvar + "=" + (e.isAnd() ? "false" : "true") + ";\n");
                var left = translateExpression(e.getLeft());
                out.append("if(" + (e.isAnd() ? "" : "!") + "(" + left + ")){\n");
                var right = translateExpression(e.getRight());
                out.append(tmpvar + "=" + right + ";\n");
                out.append("}\n");
                return null;
            }

            @Override
            public String visitIs(CJIRIs e, Void a) {
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                return "(" + left + "===" + right + ")";
            }

            @Override
            public String visitNullWrap(CJIRNullWrap e, Void a) {
                return e.getInner().map(i -> translateExpression(i)).getOrElse("null");
            }

            @Override
            public String visitListDisplay(CJIRListDisplay e, Void a) {
                var args = e.getExpressions().map(i -> translateExpression(i));
                return "[" + Str.join(",", args) + "]";
            }

            @Override
            public String visitTupleDisplay(CJIRTupleDisplay e, Void a) {
                var args = e.getExpressions().map(i -> translateExpression(i));
                return "[" + Str.join(",", args) + "]";
            }

            @Override
            public String visitIf(CJIRIf e, Void a) {
                var condition = translateExpression(e.getCondition());
                var tmpvar = ctx.newTempVarName();
                out.append("let " + tmpvar + ";\n");
                out.append("if(" + condition + "){\n");
                var left = translateExpression(e.getLeft());
                out.append(tmpvar + "=" + left + ";\n");
                out.append("}else{\n");
                var right = translateExpression(e.getRight());
                out.append(tmpvar + "=" + right + ";\n");
                out.append("}\n");
                return null;
            }

            @Override
            public String visitIfNull(CJIRIfNull e, Void a) {
                var inner = translateExpressionToVariableOrLiteral(e.getExpression());
                var tmpvar = ctx.newTempVarName();
                out.append("let " + tmpvar + ";\n");
                out.append("if(" + inner + "!==null){\n");
                var target = translateTarget(e.getTarget());
                out.append("let " + target + "=" + inner + ";\n");
                var left = translateExpression(e.getLeft());
                out.append(tmpvar + "=" + left + ";\n");
                out.append("}else{\n");
                out.append(tmpvar + "=" + translateExpression(e.getRight()) + ";\n");
                out.append("}\n");
                return tmpvar;
            }

            @Override
            public String visitWhile(CJIRWhile e, Void a) {
                out.append("while(true){\n");
                var condition = translateExpression(e.getCondition());
                out.append("if(!(" + condition + "))break;\n");
                translateExpression(e.getBody());
                out.append("}\n");
                return "undefined";
            }

            @Override
            public String visitFor(CJIRFor e, Void a) {
                var iterator = translateExpression(e.getIterator());
                var target = translateTarget(e.getTarget());
                out.append("for(const " + target + " of " + iterator + "){\n");
                if (e.getIfCondition().isPresent()) {
                    var condition = translateExpression(e.getIfCondition().get());
                    out.append("if(!(" + condition + "))continue;\n");
                }
                if (e.getWhileCondition().isPresent()) {
                    var condition = translateExpression(e.getWhileCondition().get());
                    out.append("if(!(" + condition + "))break;\n");
                }
                translateExpression(e.getBody());
                out.append("}\n");
                return "undefined";
            }

            @Override
            public String visitUnion(CJIRUnion e, Void a) {
                // TODO Auto-generated method stub
                throw new RuntimeException("TODO");
            }

            @Override
            public String visitSwitch(CJIRSwitch e, Void a) {
                // TODO Auto-generated method stub
                throw new RuntimeException("TODO");
            }

            @Override
            public String visitLambda(CJIRLambda e, Void a) {
                // TODO Auto-generated method stub
                throw new RuntimeException("TODO");
            }

            @Override
            public String visitReturn(CJIRReturn e, Void a) {
                // TODO Auto-generated method stub
                throw new RuntimeException("TODO");
            }

            @Override
            public String visitAwait(CJIRAwait e, Void a) {
                // TODO Auto-generated method stub
                throw new RuntimeException("TODO");
            }

            @Override
            public String visitThrow(CJIRThrow e, Void a) {
                // TODO Auto-generated method stub
                throw new RuntimeException("TODO");
            }

            @Override
            public String visitTry(CJIRTry e, Void a) {
                // TODO Auto-generated method stub
                throw new RuntimeException("TODO");
            }
        }, null);
    }
}
