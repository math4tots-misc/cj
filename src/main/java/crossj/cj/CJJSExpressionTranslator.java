package crossj.cj;

import crossj.base.Assert;
import crossj.base.Func1;
import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Str;
import crossj.cj.ir.meta.CJIRClassType;
import crossj.cj.ir.meta.CJIRType;

public final class CJJSExpressionTranslator extends CJJSTranslatorBase {
    CJJSExpressionTranslator(CJJSContext ctx, CJIRItem item, CJIRClassType selfType) {
        super(ctx, item, selfType);
    }

    CJJSBlob translateExpression(CJIRExpression expression) {
        return expression.accept(new CJIRExpressionVisitor<CJJSBlob, Void>() {

            @Override
            public CJJSBlob visitLiteral(CJIRLiteral e, Void a) {
                switch (e.getKind()) {
                case Unit:
                    return CJJSBlob.pure("undefined");
                case Char:
                    return CJJSBlob.pure("" + CJToken.charLiteralToInt(e.getRawText(), e.getMark()));
                case Bool:
                case Int:
                case Double:
                case String:
                case BigInt:
                    return CJJSBlob.pure(e.getRawText());
                }
                throw CJError.of("TODO: " + e.getKind(), e.getMark());
            }

            @Override
            public CJJSBlob visitBlock(CJIRBlock e, Void a) {
                var exprs = e.getExpressions();
                var returns = !e.getType().isUnitType();
                var tmpvar = returns ? ctx.newTempVarName() : "undefined";
                return CJJSBlob.withPrep(out -> {
                    if (returns) {
                        out.append("let " + tmpvar + ";");
                    }
                    out.append("{");
                    for (int i = 0; i + 1 < exprs.size(); i++) {
                        translateExpression(exprs.get(i)).emitDrop(out);
                    }
                    var last = translateExpression(exprs.last());
                    if (returns) {
                        last.emitSet(out, tmpvar + "=");
                    } else {
                        last.emitDrop(out);
                    }
                    out.append("}");
                    return null;
                }, out -> {
                    out.append(tmpvar);
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitMethodCall(CJIRMethodCall e, Void a) {
                var typeArgs = e.getMethodRef().isGeneric() ? e.getTypeArgs().map(i -> "null")
                        : translateTypeArgs(e.getMethodRef().getMethod().getTypeParameters(), e.getTypeArgs());
                var args0 = e.getArgs().map(CJJSExpressionTranslator.this::translateExpression);
                var args = args0.all(arg -> arg.isSimple()) ? args0 : args0.map(arg -> arg.toPure(ctx));

                Optional<Func1<Void, CJJSSink>> prep = args.all(arg -> arg.isSimple()) ? Optional.empty()
                        : Optional.of(out -> {
                            for (var arg : args) {
                                arg.emitPrep(out);
                            }
                            return null;
                        });
                var allArgs = List.of(typeArgs.map(CJJSBlob::pure), args).flatMap(x -> x);
                var call = joinMethodCall(prep, e.getMark(), e.getOwner(), e.getMethodRef(), e.getArgs(), allArgs);
                Optional<Func1<Void, CJJSSink>> newPrep = prep.isPresent() || call.getPrep().isPresent()
                        ? Optional.of(out -> {
                            if (prep.isPresent()) {
                                prep.get().apply(out);
                            }
                            if (call.getPrep().isPresent()) {
                                call.getPrep().get().apply(out);
                            }
                            return null;
                        })
                        : Optional.empty();
                return new CJJSBlob(newPrep, call.getMain(), call.isPure());
            }

            private CJJSBlob joinOp(String prefix, String suffix, String sep, List<CJJSBlob> args) {
                return CJJSBlob.simple(out -> {
                    out.append(prefix);
                    for (int i = 0; i < args.size(); i++) {
                        if (i > 0) {
                            out.append(sep);
                        }
                        args.get(i).emitMain(out);
                    }
                    out.append(suffix);
                    return null;
                });
            }

            private CJJSBlob joinMethodCall(Optional<Func1<Void, CJJSSink>> prep, CJMark mark, CJIRType owner,
                    CJIRMethodRef methodRef, List<CJIRExpression> args, List<CJJSBlob> allArgs) {
                var fullMethodName = methodRef.getOwner().getItem().getFullName() + "." + methodRef.getName();
                switch (fullMethodName) {
                case "cj.Int.__neg":
                    return joinOp("(-", ")", "", allArgs);
                case "cj.Int.__add":
                    return joinOp("((", ")|0)", "+", allArgs);
                case "cj.Int.__mul":
                    return joinOp("((", ")|0)", "*", allArgs);
                case "cj.Int.__sub":
                    return joinOp("((", ")|0)", "-", allArgs);
                case "cj.Int.__truncdiv":
                    return joinOp("((", ")|0)", "/", allArgs);
                case "cj.Int.__div":
                    return joinOp("(", ")", "/", allArgs);
                case "cj.Int.__or":
                    return joinOp("(", ")", "|", allArgs);
                case "cj.Int.__and":
                    return joinOp("(", ")", "&", allArgs);
                case "cj.Int.__xor":
                    return joinOp("(", ")", "^", allArgs);
                case "cj.Int.__lshift":
                    return joinOp("(", ")", "<<", allArgs);
                case "cj.Int.__rshift":
                    return joinOp("(", ")", ">>", allArgs);
                case "cj.Int.__rshiftu":
                    return joinOp("(", ")", ">>>", allArgs);
                case "cj.Double.__neg":
                    return joinOp("(-", ")", "", allArgs);
                case "cj.Double.__add":
                    return joinOp("(", ")", "+", allArgs);
                case "cj.Double.__mul":
                    return joinOp("(", ")", "*", allArgs);
                case "cj.Double.__sub":
                    return joinOp("(", ")", "-", allArgs);
                case "cj.Double.__truncdiv":
                    return joinOp("((", ")|0)", "/", allArgs);
                case "cj.Double.__div":
                    return joinOp("(", ")", "/", allArgs);
                case "cj.List.empty":
                    return CJJSBlob.simplestr("[]");
                case "cj.List_.empty":
                    return CJJSBlob.simplestr("[]");
                case "cj.List.__new":
                    Assert.equals(allArgs.size(), 1);
                    return allArgs.get(0).toPure(ctx);
                case "cj.List.size":
                    Assert.equals(allArgs.size(), 1);
                    return CJJSBlob.simple(out -> {
                        allArgs.get(0).emitMain(out);
                        out.append(".length");
                        return null;
                    });
                case "cj.String.__add":
                    Assert.equals(allArgs.size(), 3);
                    Assert.equals(args.size(), 2);
                    switch (args.get(1).getType().toRawQualifiedName()) {
                    case "cj.String":
                    case "cj.Int":
                    case "cj.Double":
                    case "cj.Bool":
                        return joinOp("(", ")", "+", allArgs.sliceFrom(1));
                    }
                    break;
                case "cj.Nullable.default":
                    Assert.equals(allArgs.size(), 0);
                    return CJJSBlob.pure("null");
                case "cj.Int.default":
                case "cj.Double.default":
                case "cj.Char.default":
                    Assert.equals(allArgs.size(), 0);
                    return CJJSBlob.pure("0");
                case "cj.List.default":
                    Assert.equals(allArgs.size(), 0);
                    return CJJSBlob.simplestr("[]");
                case "www.JSObject.field":
                case "www.JSWrapper.field":
                    Assert.equals(allArgs.size(), 2);
                    return CJJSBlob.simple(out -> {
                        allArgs.get(0).emitMain(out);
                        out.append("[");
                        allArgs.get(1).emitMain(out);
                        out.append("]");
                        return null;
                    });
                case "www.JSObject.setField":
                case "www.JSWrapper.setField":
                    Assert.equals(allArgs.size(), 4);
                    return CJJSBlob.withPrep(out -> {
                        allArgs.get(1).emitMain(out);
                        out.append("[");
                        allArgs.get(2).emitMain(out);
                        out.append("]=");
                        allArgs.get(3).emitMain(out);
                        out.append(";");
                        return null;
                    }, out -> {
                        out.append("undefined");
                        return null;
                    }, true);
                case "www.JSObject.call1":
                case "www.JSObject.call":
                case "www.JSWrapper.call": {
                    Assert.equals(allArgs.size(), 3);
                    return CJJSBlob.simple(out -> {
                        allArgs.get(0).emitMain(out);
                        out.append("[");
                        allArgs.get(1).emitMain(out);
                        out.append("](...");
                        allArgs.get(2).emitMain(out);
                        out.append(")");
                        return null;
                    });
                }
                case "cjx.js.JSON.fromList":
                case "cj.Double._fromInt":
                case "cj.Double.toDouble":
                case "cj.Int.toDouble":
                case "cj.Int._fromChar":
                    Assert.equals(allArgs.size(), 1);
                    return allArgs.get(0);
                case "cjx.js.JSON._unsafeCast":
                case "www.JSObject.unsafeCast":
                    Assert.equals(allArgs.size(), 2);
                    return allArgs.get(1);
                case "cj.Fn0":
                case "cj.Fn1":
                case "cj.Fn2":
                case "cj.Fn3":
                case "cj.Fn4": {
                    return CJJSBlob.simple(out -> {
                        allArgs.get(0).emitMain(out);
                        out.append("(");
                        for (int i = 1; i < allArgs.size(); i++) {
                            if (i > 1) {
                                out.append(",");
                            }
                            allArgs.get(i).emitMain(out);
                        }
                        out.append(")");
                        return null;
                    });
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
                            if (!field.isMutable() && field.getExpression().isPresent()
                                    && field.getExpression().get() instanceof CJIRLiteral) {
                                var literal = (CJIRLiteral) field.getExpression().get();
                                var result = visitLiteral(literal, null);
                                Assert.that(result.isSimpleAndPure());
                                return result;
                            }
                            break;
                        case "=":
                            Assert.equals(allArgs.size(), 1);
                            return CJJSBlob.simple(out -> {
                                out.append(target + info.getKind());
                                allArgs.last().emitMain(out);
                                return null;
                            });
                        case "+=":
                            Assert.equals(allArgs.size(), 1);
                            return CJJSBlob.simple(out -> {
                                out.append(target + "=(" + ownerStr + "." + translateMethodName(field.getGetterName())
                                        + "())+");
                                allArgs.last().emitMain(out);
                                return null;
                            });
                        }
                    } else if (!field.isStatic()) {
                        switch (info.getKind()) {
                        case "":
                            Assert.equals(allArgs.size(), 1);
                            if (field.isLateinit()) {
                                break;
                            }
                            return CJJSBlob.simple(out -> {
                                if (isWrapperType(owner)) {
                                    allArgs.get(0).emitMain(out);
                                } else {
                                    allArgs.get(0).emitMain(out);
                                    out.append("[" + field.getIndex() + "]");
                                }
                                return null;
                            });
                        case "=":
                        case "+=":
                            Assert.equals(allArgs.size(), 2);
                            Assert.that(field.isMutable());
                            Assert.that(!isWrapperType(owner));
                            return CJJSBlob.simple(out -> {
                                allArgs.get(0).emitMain(out);
                                out.append("[" + field.getIndex() + "]" + info.getKind());
                                allArgs.last().emitMain(out);
                                return null;
                            });
                        }
                    }
                }

                return CJJSBlob.simple(out -> {
                    out.append(ownerStr);
                    out.append(".");
                    out.addMark(mark);
                    out.append(translateMethodName(methodRef.getName()));
                    out.append("(");
                    for (int i = 0; i < allArgs.size(); i++) {
                        if (i > 0) {
                            out.append(",");
                        }
                        allArgs.get(i).emitMain(out);
                    }
                    out.append(")");
                    return null;
                });
            }

            @Override
            public CJJSBlob visitVariableDeclaration(CJIRVariableDeclaration e, Void a) {
                var inner = translateExpression(e.getExpression());
                return CJJSBlob.withPrep(out -> {
                    inner.emitPrep(out);
                    out.append(e.isMutable() ? "let " : "const ");
                    out.append(translateTarget(e.getTarget()));
                    out.append("=");
                    inner.emitMain(out);
                    out.append(";");
                    return null;
                }, out -> {
                    out.append("undefined");
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitVariableAccess(CJIRVariableAccess e, Void a) {
                return CJJSBlob.simple(out -> {
                    out.addMark(e.getMark());
                    out.append(translateLocalVariableName(e.getDeclaration().getName()));
                    return null;
                });
            }

            @Override
            public CJJSBlob visitAssignment(CJIRAssignment e, Void a) {
                var expr = translateExpression(e.getExpression());
                var target = translateLocalVariableName(e.getVariableName());
                return CJJSBlob.withPrep(out -> {
                    expr.emitSet(out, target + "=");
                    return null;
                }, out -> {
                    out.append("undefined");
                    return null;
                }, true);
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

                return CJJSBlob.withPrep(out -> {
                    if (e.getKind() == CJIRAugAssignKind.Add && isOne(e.getExpression())) {
                        out.append(target + "++;");
                    } else if (e.getKind() == CJIRAugAssignKind.Subtract && isOne(e.getExpression())) {
                        out.append(target + "--;");
                    } else {
                        augexpr.emitPrep(out);
                        out.append(target + op);
                        augexpr.emitMain(out);
                        out.append(";");
                    }
                    return null;
                }, out -> {
                    out.append("undefined");
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitLogicalNot(CJIRLogicalNot e, Void a) {
                var inner = translateExpression(e.getInner());
                return new CJJSBlob(inner.getPrep(), out -> {
                    out.append("(!");
                    inner.emitMain(out);
                    out.append(")");
                    return null;
                }, inner.isPure());
            }

            @Override
            public CJJSBlob visitLogicalBinop(CJIRLogicalBinop e, Void a) {
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                if (left.isSimple() && right.isSimple()) {
                    var op = e.isAnd() ? "&&" : "||";
                    return CJJSBlob.simple(out -> {
                        out.append("((");
                        left.emitMain(out);
                        out.append(")" + op + "(");
                        right.emitMain(out);
                        out.append("))");
                        return null;
                    });
                } else {
                    var tmpvar = ctx.newTempVarName();
                    return CJJSBlob.withPrep(out -> {
                        out.append("let " + tmpvar + "=" + (e.isAnd() ? "false" : "true") + ";");
                        left.emitPrep(out);
                        out.append("if(" + (e.isAnd() ? "" : "!") + "(");
                        left.emitMain(out);
                        out.append(")){");
                        right.emitSet(out, tmpvar + "=");
                        out.append("}");
                        return null;
                    }, out -> {
                        out.append(tmpvar);
                        return null;
                    }, true);
                }
            }

            @Override
            public CJJSBlob visitIs(CJIRIs e, Void a) {
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                if (left.isSimple() && right.isSimple()) {
                    return CJJSBlob.simple(out -> {
                        out.append("(");
                        left.emitMain(out);
                        out.append("===");
                        right.emitMain(out);
                        out.append(")");
                        return null;
                    });
                } else {
                    var pureLeft = left.toPure(ctx);
                    return CJJSBlob.withPrep(out -> {
                        pureLeft.emitPrep(out);
                        right.emitPrep(out);
                        return null;
                    }, out -> {
                        out.append("(");
                        pureLeft.emitMain(out);
                        out.append("===");
                        right.emitMain(out);
                        out.append(")");
                        return null;
                    }, false);
                }
            }

            @Override
            public CJJSBlob visitNullWrap(CJIRNullWrap e, Void a) {
                return e.getInner().map(i -> translateExpression(i)).getOrElseDo(() -> CJJSBlob.pure("null"));
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
                var args = expressions.map(arg -> translateExpression(arg));
                if (args.all(arg -> arg.isSimple())) {
                    return CJJSBlob.simple(out -> {
                        out.append("[");
                        for (int i = 0; i < args.size(); i++) {
                            if (i > 0) {
                                out.append(",");
                            }
                            args.get(i).emitMain(out);
                        }
                        out.append("]");
                        return null;
                    });
                }
                var pureArgs = args.map(arg -> arg.toPure(ctx));
                return CJJSBlob.withPrep(out -> {
                    for (var arg : pureArgs) {
                        arg.emitPrep(out);
                    }
                    return null;
                }, out -> {
                    out.append("[");
                    for (int i = 0; i < pureArgs.size(); i++) {
                        if (i > 0) {
                            out.append(",");
                        }
                        args.get(i).emitMain(out);
                    }
                    out.append("]");
                    return null;
                }, false);
            }

            @Override
            public CJJSBlob visitIf(CJIRIf e, Void a) {
                var condition = translateExpression(e.getCondition());
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                if (condition.isSimple() && left.isSimple() && right.isSimple()) {
                    return CJJSBlob.simple(out -> {
                        out.append("(");
                        condition.emitMain(out);
                        out.append("?");
                        left.emitMain(out);
                        out.append(":");
                        right.emitMain(out);
                        out.append(")");
                        return null;
                    });
                } else {
                    var tmpvar = ctx.newTempVarName();
                    return CJJSBlob.withPrep(out -> {
                        out.append("let " + tmpvar + ";");
                        condition.emitPrep(out);
                        out.append("if(");
                        condition.emitMain(out);
                        out.append("){");
                        left.emitSet(out, tmpvar + "=");
                        out.append("}else{");
                        right.emitSet(out, tmpvar + "=");
                        out.append("}");
                        return null;
                    }, out -> {
                        out.append(tmpvar);
                        return null;
                    }, true);
                }
            }

            @Override
            public CJJSBlob visitIfNull(CJIRIfNull e, Void a) {
                var inner = translateExpression(e.getExpression()).toPure(ctx);
                var target = translateTarget(e.getTarget());
                var left = translateExpression(e.getLeft());
                var right = translateExpression(e.getRight());
                var tmpvar = ctx.newTempVarName();

                return CJJSBlob.withPrep(out -> {
                    out.append("let " + tmpvar + ";");
                    inner.emitPrep(out);
                    out.append("if((");
                    inner.emitMain(out);
                    out.append(")!==null){");
                    out.append("let " + target + "=");
                    inner.emitMain(out);
                    out.append(";");
                    left.emitSet(out, tmpvar + "=");
                    out.append("}else{");
                    right.emitSet(out, tmpvar + "=");
                    out.append("}");
                    return null;
                }, out -> {
                    out.append(tmpvar);
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitWhile(CJIRWhile e, Void a) {
                var condition = translateExpression(e.getCondition());
                var body = translateExpression(e.getBody());
                return CJJSBlob.withPrep(out -> {
                    if (condition.isSimple()) {
                        out.append("while(");
                        condition.emitMain(out);
                        out.append("){");
                    } else {
                        out.append("while(true){");
                        condition.emitPrep(out);
                        out.append("if(!(");
                        condition.emitMain(out);
                        out.append("))break;");
                    }
                    body.emitDrop(out);
                    out.append("}");
                    return null;
                }, out -> {
                    out.append("undefined");
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitFor(CJIRFor e, Void a) {
                var iterator = translateExpression(e.getIterator());
                var target = translateTarget(e.getTarget());
                var body = translateExpression(e.getBody());
                return CJJSBlob.withPrep(out -> {
                    iterator.emitPrep(out);
                    out.append("for (const " + target + " of ");
                    iterator.emitMain(out);
                    out.append("){");
                    body.emitDrop(out);
                    out.append("}");
                    return null;
                }, out -> {
                    out.append("undefined");
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitWhen(CJIRWhen e, Void a) {
                var target = translateExpression(e.getTarget()).toPure(ctx);
                var tmpvar = ctx.newTempVarName();
                return CJJSBlob.withPrep(out -> {
                    target.emitPrep(out);
                    out.append("let " + tmpvar + ";");
                    if (e.getTarget().getType().isSimpleUnion()) {
                        out.append("switch(");
                        target.emitMain(out);
                        out.append("){");
                    } else {
                        out.append("switch((");
                        target.emitMain(out);
                        out.append(")[0]){");
                    }
                    for (var entry : e.getCases()) {
                        var caseDefn = entry.get2();
                        var body = translateExpression(entry.get5());
                        var tag = caseDefn.getTag();
                        var names = entry.get3().map(d -> translateLocalVariableName(d.getName()));
                        var mutable = entry.get3().any(d -> d.isMutable());
                        var prefix = mutable ? "let " : "const ";
                        out.append("case " + tag + ":{");
                        if (!e.getTarget().getType().isSimpleUnion()) {
                            out.append(prefix + "[," + Str.join(",", names) + "]=");
                            target.emitMain(out);
                            out.append(";");
                        }
                        body.emitSet(out, tmpvar + "=");
                        out.append("break;");
                        out.append("}");
                    }
                    if (e.getFallback().isPresent()) {
                        var fallback = translateExpression(e.getFallback().get());
                        out.append("default:{");
                        fallback.emitSet(out, tmpvar + "=");
                        out.append("}");
                    } else {
                        out.append("default:throw new Error(\"Invalid tag\");");
                    }
                    out.append("}");
                    return null;
                }, out -> {
                    out.append(tmpvar);
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitSwitch(CJIRSwitch e, Void a) {
                var target = translateExpression(e.getTarget());
                var tmpvar = ctx.newTempVarName();

                return CJJSBlob.withPrep(out -> {
                    target.emitPrep(out);
                    out.append("let " + tmpvar + ";");
                    out.append("switch(");
                    target.emitMain(out);
                    out.append("){");
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
                            out.append("case ");
                            value.emitMain(out);
                            out.append(":");
                        }
                        out.append("{");
                        var body = translateExpression(case_.get2());
                        body.emitSet(out, tmpvar + "=");
                        out.append("break;");
                        out.append("}");
                    }
                    out.append("default:");
                    if (e.getFallback().isPresent()) {
                        out.append("{");
                        var fallback = translateExpression(e.getFallback().get());
                        fallback.emitSet(out, tmpvar + "=");
                        out.append("}");
                    } else {
                        out.append("throw new Error('Unhandled switch case');");
                    }
                    out.append("}");
                    return null;
                }, out -> {
                    out.append(tmpvar);
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitLambda(CJIRLambda e, Void a) {
                var parameters = e.getParameters();
                var parameterNames = parameters.map(p -> translateLocalVariableName(p.getName()));
                var paramstr = "(" + Str.join(",", parameterNames) + ")=>";
                var blob = translateExpression(e.getBody());

                if (blob.isSimple()) {
                    return CJJSBlob.simple(out -> {
                        out.append(paramstr + "(");
                        blob.emitMain(out);
                        out.append(")");
                        return null;
                    });
                } else {
                    return CJJSBlob.simple(out -> {
                        out.append("(" + paramstr + "{");
                        if (e.getReturnType().isUnitType()) {
                            blob.emitDrop(out);
                        } else {
                            blob.emitSet(out, "return ");
                        }
                        out.append("}");
                        out.append(")");
                        return null;
                    });
                }
            }

            @Override
            public CJJSBlob visitReturn(CJIRReturn e, Void a) {
                var inner = translateExpression(e.getExpression());
                return CJJSBlob.withPrep(out -> {
                    inner.emitSet(out, "return ");
                    return null;
                }, out -> {
                    out.append("undefined");
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitAwait(CJIRAwait e, Void a) {
                var inner = translateExpression(e.getInner());
                return new CJJSBlob(inner.getPrep(), out -> {
                    out.append("(await ");
                    inner.emitMain(out);
                    out.append(")");
                    return null;
                }, false);
            }

            @Override
            public CJJSBlob visitThrow(CJIRThrow e, Void a) {
                var inner = translateExpression(e.getExpression());
                var type = translateType(e.getExpression().getType());
                return CJJSBlob.withPrep(out -> {
                    inner.emitPrep(out);
                    out.addMark(e.getMark());
                    out.append("throw ");
                    if (e.getExpression().getType().repr().equals("cj.Error")) {
                        inner.emitMain(out);
                    } else {
                        out.append("new WrappingException(");
                        out.append(type + ",");
                        inner.emitMain(out);
                        out.append(")");
                    }
                    out.append(";");
                    return null;
                }, out -> {
                    out.append("undefined");
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitTry(CJIRTry e, Void a) {
                var tmpvar = ctx.newTempVarName();
                var body = translateExpression(e.getBody());
                var xclauses = e.getClauses().filter(c -> !c.get2().repr().equals("cj.Error"));
                var yclauses = e.getClauses().filter(c -> c.get2().repr().equals("cj.Error"));

                return CJJSBlob.withPrep(out -> {
                    out.append("let " + tmpvar + ";");
                    out.append("try{");
                    body.emitSet(out, tmpvar + "=");
                    if (e.getClauses().size() > 0) {
                        out.append("}catch(w){");

                        if (xclauses.size() > 0) {
                            out.append("if(w instanceof WrappingException){const t=w.typeId;");
                            for (int i = 0; i < xclauses.size(); i++) {
                                var clause = xclauses.get(i);
                                out.append(i == 0 ? "if" : "else if");
                                out.append("(typeEq(t," + translateType(clause.get2()) + ")){");
                                out.append("const " + translateTarget(clause.get1()) + "=w.data;");
                                var clauseBody = translateExpression(clause.get3());
                                clauseBody.emitSet(out, tmpvar + "=");
                                out.append("}");
                            }
                            out.append("else{throw w;}");
                            out.append("}else{");
                        } else {
                            out.append("{");
                        }
                        if (yclauses.size() > 0) {
                            if (yclauses.size() != 1) {
                                throw CJError.of("More than one clause catching cj.Error", e.getMark());
                            }
                            var clause = yclauses.get(0);
                            out.append("if(w instanceof Error){");
                            out.append("const " + translateTarget(clause.get1()) + "=w;");
                            var clauseBody = translateExpression(clause.get3());
                            clauseBody.emitSet(out, tmpvar + "=");
                            out.append("}else{throw w;}");
                        } else {
                            out.append("throw w;");
                        }
                        out.append("}");
                    }
                    out.append("}");
                    if (e.getFin().isPresent()) {
                        out.append("finally{");
                        translateExpression(e.getFin().get()).emitDrop(out);
                        out.append("}");
                    }
                    return null;
                }, out -> {
                    out.append(tmpvar);
                    return null;
                }, true);
            }

            @Override
            public CJJSBlob visitTag(CJIRTag e, Void a) {
                var inner = translateExpression(e.getTarget());
                if (e.getTarget().getType().isSimpleUnion()) {
                    return inner;
                } else {
                    return new CJJSBlob(inner.getPrep(), out -> {
                        inner.emitMain(out);
                        out.append("[0]");
                        return null;
                    }, false);
                }
            }

            @Override
            public CJJSBlob visitJSBlob(CJIRJSBlob e, Void a) {
                var parts = e.getParts().map(p -> (p instanceof String) ? p : translateExpression((CJIRExpression) p));
                var blobs0 = parts.filter(p -> p instanceof CJJSBlob).map(p -> (CJJSBlob) p);
                var blobs = blobs0.all(b -> b.isSimple()) ? blobs0 : blobs0.map(b -> b.toPure(ctx));
                var prep = joinPreps(blobs.map(b -> b.getPrep()));
                return new CJJSBlob(prep, out -> {
                    out.append("(");
                    for (var part : parts) {
                        if (part instanceof String) {
                            out.append((String) part);
                        } else {
                            ((CJJSBlob) part).emitMain(out);
                        }
                    }
                    out.append(")");
                    return null;
                }, false);
            }

            @Override
            public CJJSBlob visitIsSet(CJIRIsSet e, Void a) {
                if (e.getOwner().isPresent()) {
                    var owner = translateExpression(e.getOwner().get());
                    return new CJJSBlob(owner.getPrep(), out -> {
                        out.append("(");
                        owner.emitMain(out);
                        out.append("[" + e.getField().getIndex() + "]!==undefined)");
                        return null;
                    }, false);
                } else {
                    var ownerType = translateType(e.getOwnerType());
                    var fieldName = translateFieldName(e.getField().getName());
                    return CJJSBlob.simplestr("(\"" + fieldName + "\" in " + ownerType + ")");
                }
            }
        }, null);
    }

    static Optional<Func1<Void, CJJSSink>> joinPreps(List<Optional<Func1<Void, CJJSSink>>> prepList) {
        if (prepList.all(p -> p.isEmpty())) {
            return Optional.empty();
        }
        var preps = prepList.flatMap(p -> p);
        return Optional.of(out -> {
            for (var prep : preps) {
                prep.apply(out);
            }
            return null;
        });
    }
}
