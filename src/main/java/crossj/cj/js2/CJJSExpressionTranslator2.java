package crossj.cj.js2;

import java.util.function.BiConsumer;
import java.util.function.Consumer;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Str;
import crossj.cj.CJError;
import crossj.cj.CJMark;
import crossj.cj.CJToken;
import crossj.cj.ir.CJIRAssignment;
import crossj.cj.ir.CJIRAssignmentTarget;
import crossj.cj.ir.CJIRAssignmentTargetVisitor;
import crossj.cj.ir.CJIRAugAssignKind;
import crossj.cj.ir.CJIRAugmentedAssignment;
import crossj.cj.ir.CJIRAwait;
import crossj.cj.ir.CJIRBlock;
import crossj.cj.ir.CJIRCaseMethodInfo;
import crossj.cj.ir.CJIRExpression;
import crossj.cj.ir.CJIRExpressionVisitor;
import crossj.cj.ir.CJIRFieldMethodInfo;
import crossj.cj.ir.CJIRFor;
import crossj.cj.ir.CJIRIf;
import crossj.cj.ir.CJIRIfNull;
import crossj.cj.ir.CJIRIs;
import crossj.cj.ir.CJIRIsSet;
import crossj.cj.ir.CJIRJSBlob;
import crossj.cj.ir.CJIRLambda;
import crossj.cj.ir.CJIRListDisplay;
import crossj.cj.ir.CJIRLiteral;
import crossj.cj.ir.CJIRLogicalBinop;
import crossj.cj.ir.CJIRLogicalNot;
import crossj.cj.ir.CJIRMethodCall;
import crossj.cj.ir.CJIRNameAssignmentTarget;
import crossj.cj.ir.CJIRNullWrap;
import crossj.cj.ir.CJIRReturn;
import crossj.cj.ir.CJIRSwitch;
import crossj.cj.ir.CJIRTag;
import crossj.cj.ir.CJIRThrow;
import crossj.cj.ir.CJIRTry;
import crossj.cj.ir.CJIRTupleAssignmentTarget;
import crossj.cj.ir.CJIRTupleDisplay;
import crossj.cj.ir.CJIRVariableAccess;
import crossj.cj.ir.CJIRVariableDeclaration;
import crossj.cj.ir.CJIRWhen;
import crossj.cj.ir.CJIRWhile;
import crossj.cj.js.CJJSSink;

final class CJJSExpressionTranslator2 {
    private final CJJSTempVarFactory varFactory;
    private final CJJSMethodNameRegistry methodNameRegistry;
    private final CJJSTypeBinding binding;
    private final Consumer<CJJSLLMethod> requestMethod;
    private final BiConsumer<String, CJMark> requestNative;
    private final CJJSTypeIdRegistry typeIdRegistry;

    CJJSExpressionTranslator2(CJJSTypeIdRegistry typeIdRegistry, CJJSTempVarFactory varFactory,
            CJJSMethodNameRegistry methodNameRegistry, CJJSTypeBinding binding, Consumer<CJJSLLMethod> requestMethod,
            BiConsumer<String, CJMark> requestNative) {
        this.typeIdRegistry = typeIdRegistry;
        this.varFactory = varFactory;
        this.methodNameRegistry = methodNameRegistry;
        this.binding = binding;
        this.requestMethod = requestMethod;
        this.requestNative = requestNative;
    }

    CJJSBlob2 translate(CJIRExpression expression) {
        return expression.accept(new CJIRExpressionVisitor<CJJSBlob2, Void>() {

            @Override
            public CJJSBlob2 visitLiteral(CJIRLiteral e, Void a) {
                switch (e.getKind()) {
                case Unit:
                    return CJJSBlob2.pure("undefined");
                case Char:
                    return CJJSBlob2.pure("" + CJToken.charLiteralToInt(e.getRawText(), e.getMark()));
                case Bool:
                case Int:
                case Double:
                case String:
                case BigInt:
                    return CJJSBlob2.pure(e.getRawText());
                }
                throw CJError.of("TODO: " + e.getKind(), e.getMark());
            }

            @Override
            public CJJSBlob2 visitBlock(CJIRBlock e, Void a) {
                var exprs = e.getExpressions();
                var returns = !e.getType().isUnitType();
                var tmpvar = returns ? varFactory.newName() : "undefined";
                return CJJSBlob2.withPrep(out -> {
                    if (returns) {
                        out.append("let " + tmpvar + ";");
                    }
                    out.append("{");
                    for (int i = 0; i + 1 < exprs.size(); i++) {
                        translate(exprs.get(i)).emitDrop(out);
                    }
                    var last = translate(exprs.last());
                    if (returns) {
                        last.emitSet(out, tmpvar + "=");
                    } else {
                        last.emitDrop(out);
                    }
                    out.append("};");
                }, out -> {
                    out.append(tmpvar);
                }, true);
            }

            @Override
            public CJJSBlob2 visitMethodCall(CJIRMethodCall e, Void a) {

                var inliner = new CJJSInliner2(CJJSExpressionTranslator2.this);
                var optInlinedBlob = inliner.tryInline(e);
                if (optInlinedBlob.isPresent()) {
                    return optInlinedBlob.get();
                }

                var args = e.getArgs().map(arg -> translate(arg));
                var owner = binding.apply(e.getOwner());
                var reifiedMethodRef = e.getReifiedMethodRef();
                var llmethod = binding.translate(owner, reifiedMethodRef);

                var key = owner.getItem().getFullName() + "." + reifiedMethodRef.getName();

                var op = CJJSOps.OPS.getOrNull(key);
                if (op != null) {
                    var ctx = new CJJSOps.Context(key, binding, e, args, owner, reifiedMethodRef, llmethod,
                            requestMethod, requestNative, varFactory);
                    var blob = op.apply(ctx);
                    if (blob != null) {
                        return blob;
                    }
                }

                var ownersMethod = owner.getItem().getMethodOrNull(e.getName());

                var isNative = owner.isNative() && ownersMethod != null && ownersMethod.getBody().isEmpty();

                if (isNative) {
                    requestNative.accept(key + ".js", e.getMark());
                    return translateCall(e.getMark(), key.replace(".", "$"), args);
                }

                var extra = llmethod.getMethod().getExtra();

                if (extra instanceof CJIRFieldMethodInfo) {
                    var fmi = (CJIRFieldMethodInfo) extra;
                    var field = fmi.getField();
                    if (!field.isStatic()) {
                        var fieldIndex = field.getIndex();
                        switch (fmi.getKind()) {
                        case "":
                            if (field.isLateinit()) {
                                return translateParts(args, "defined(", "[" + fieldIndex + "])");
                            } else {
                                return CJJSTranslator2.isWrapperType(owner) ? args.get(0)
                                        : translateParts(args, "", "[" + fieldIndex + "]");
                            }
                        case "=":
                            return translateParts(args, "(", "[" + fieldIndex + "]=", ")");
                        case "+=":
                            return translateParts(args, "(", "[" + fieldIndex + "]+=", ")");
                        default:
                            throw new RuntimeException("Unrecognized kind " + fmi.getKind());
                        }
                    }
                } else if (extra instanceof CJIRCaseMethodInfo) {
                    var cmi = (CJIRCaseMethodInfo) extra;
                    var case_ = cmi.getCase();
                    return new CJJSBlob2(joinPreps(args.map(x -> x.getPrep())), out -> {
                        if (owner.isSimpleUnion()) {
                            Assert.equals(args.size(), 0);
                            out.append("" + case_.getTag());
                        } else {
                            out.append("[" + case_.getTag());
                            for (var arg : args) {
                                out.append(",");
                                arg.emitBody(out);
                            }
                            out.append("]");
                        }
                    }, false);
                }

                requestMethod.accept(llmethod);
                var jsMethodName = methodNameRegistry.nameForReifiedMethod(llmethod);

                // regular call
                return translateCall(e.getMark(), jsMethodName, args);
            }

            @Override
            public CJJSBlob2 visitVariableDeclaration(CJIRVariableDeclaration e, Void a) {
                var prefix = e.isMutable() ? "let " : "const ";
                return CJJSBlob2.unit(out -> {
                    out.addMark(e.getMark());
                    var target = prefix + translateTarget(e.getTarget()) + "=";
                    translate(e.getExpression()).emitSet(out, target);
                });
            }

            @Override
            public CJJSBlob2 visitVariableAccess(CJIRVariableAccess e, Void a) {
                return CJJSBlob2.pure("L$" + e.getDeclaration().getName());
            }

            @Override
            public CJJSBlob2 visitAssignment(CJIRAssignment e, Void a) {
                return CJJSBlob2.unit(out -> {
                    translate(e.getExpression()).emitSet(out, "L$" + e.getVariableName() + "=");
                });
            }

            @Override
            public CJJSBlob2 visitAugmentedAssignment(CJIRAugmentedAssignment e, Void a) {
                var target = "L$" + e.getTarget().getName();
                var augexpr = translate(e.getExpression());
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

                return CJJSBlob2.withPrep(out -> {
                    if (e.getKind() == CJIRAugAssignKind.Add && isOne(e.getExpression())) {
                        out.append(target + "++;");
                    } else if (e.getKind() == CJIRAugAssignKind.Subtract && isOne(e.getExpression())) {
                        out.append(target + "--;");
                    } else {
                        augexpr.emitPrep(out);
                        out.append(target + op);
                        augexpr.emitBody(out);
                        out.append(";");
                    }
                }, out -> {
                    out.append("undefined");
                }, true);
            }

            @Override
            public CJJSBlob2 visitLogicalNot(CJIRLogicalNot e, Void a) {
                return translateParts(List.of(translate(e.getInner())), "(!", ")");
            }

            @Override
            public CJJSBlob2 visitLogicalBinop(CJIRLogicalBinop e, Void a) {
                var lhs = translate(e.getLeft());
                var rhs = translate(e.getRight());
                if (rhs.isSimple()) {
                    return translateParts(List.of(lhs, rhs), "(",
                            e.isAnd() ? "&&" : "||", ")");
                } else {
                    var tmpvar = varFactory.newName();
                    return CJJSBlob2.withPrep(out -> {
                        lhs.emitSet(out, "let " + tmpvar + "=");
                        if (e.isAnd()) {
                            out.append("if(" + tmpvar + "){");
                        } else {
                            out.append("if(!" + tmpvar + "){");
                        }
                        rhs.emitSet(out, tmpvar + "=");
                        out.append("}");
                    }, out -> {
                        out.append(tmpvar);
                    }, true);
                }
            }

            @Override
            public CJJSBlob2 visitIs(CJIRIs e, Void a) {
                return translateOp("(", ")", "===", List.of(translate(e.getLeft()), translate(e.getRight())));
            }

            @Override
            public CJJSBlob2 visitNullWrap(CJIRNullWrap e, Void a) {
                return e.getInner().isPresent() ? translate(e.getInner().get()) : CJJSBlob2.pure("null");
            }

            @Override
            public CJJSBlob2 visitListDisplay(CJIRListDisplay e, Void a) {
                return translateOp("[", "]", ",", e.getExpressions().map(x -> translate(x)));
            }

            @Override
            public CJJSBlob2 visitTupleDisplay(CJIRTupleDisplay e, Void a) {
                return translateOp("[", "]", ",", e.getExpressions().map(x -> translate(x)));
            }

            @Override
            public CJJSBlob2 visitIf(CJIRIf e, Void a) {
                var condition = translate(e.getCondition());
                var left = translate(e.getLeft());
                var right = translate(e.getRight());
                if (List.of(left, right).all(x -> x.isSimple())) {
                    return new CJJSBlob2(condition.getPrep(), out -> {
                        out.append("(");
                        condition.emitBody(out);
                        out.append("?");
                        left.emitBody(out);
                        out.append(":");
                        right.emitBody(out);
                        out.append(")");
                    }, false);
                }
                var tmpvar = varFactory.newName();
                return CJJSBlob2.withPrep(out -> {
                    out.append("let " + tmpvar + ";");
                    condition.emitPrep(out);
                    out.append("if(");
                    condition.emitBody(out);
                    out.append("){");
                    left.emitSet(out, tmpvar + "=");
                    out.append("}else{");
                    right.emitSet(out, tmpvar + "=");
                    out.append("}");
                }, out -> out.append(tmpvar), true);
            }

            @Override
            public CJJSBlob2 visitIfNull(CJIRIfNull e, Void a) {
                var inner = translate(e.getExpression()).toPure(varFactory::newName);
                var target = translateTarget(e.getTarget());
                var left = translate(e.getLeft());
                var right = translate(e.getRight());
                var tmpvar = varFactory.newName();
                return CJJSBlob2.withPrep(out -> {
                    out.append("let " + tmpvar + ";");
                    inner.emitPrep(out);
                    out.append("if((");
                    inner.emitBody(out);
                    out.append(")!==null){");
                    out.append("let " + target + "=");
                    inner.emitBody(out);
                    out.append(";");
                    left.emitSet(out, tmpvar + "=");
                    out.append("}else{");
                    right.emitSet(out, tmpvar + "=");
                    out.append("}");
                }, out -> out.append(tmpvar), true);
            }

            @Override
            public CJJSBlob2 visitWhile(CJIRWhile e, Void a) {
                var cond = translate(e.getCondition());
                var body = translate(e.getBody());
                return CJJSBlob2.withPrep(out -> {
                    if (cond.isSimple()) {
                        out.append("while(");
                        cond.emitBody(out);
                        out.append("){");
                        body.emitDrop(out);
                        out.append("}");
                    } else {
                        out.append("while(true){");
                        cond.emitPrep(out);
                        out.append("if(!(");
                        cond.emitBody(out);
                        out.append("))break;");
                        body.emitDrop(out);
                        out.append("}");
                    }
                }, out -> out.append("undefined"), true);
            }

            @Override
            public CJJSBlob2 visitFor(CJIRFor e, Void a) {
                var iterator = translate(e.getIterator());
                var target = translateTarget(e.getTarget());
                var body = translate(e.getBody());
                return CJJSBlob2.withPrep(out -> {
                    iterator.emitPrep(out);
                    out.append("for (const " + target + " of ");
                    iterator.emitBody(out);
                    out.append("){");
                    body.emitDrop(out);
                    out.append("}");
                }, out -> {
                    out.append("undefined");
                }, true);
            }

            @Override
            public CJJSBlob2 visitWhen(CJIRWhen e, Void a) {
                var target = translate(e.getTarget()).toPure(varFactory::newName);
                var tmpvar = varFactory.newName();
                return CJJSBlob2.withPrep(out -> {
                    target.emitPrep(out);
                    out.append("let " + tmpvar + ";");
                    if (e.getTarget().getType().isSimpleUnion()) {
                        out.append("switch(");
                        target.emitBody(out);
                        out.append("){");
                    } else {
                        out.append("switch((");
                        target.emitBody(out);
                        out.append(")[0]){");
                    }
                    for (var entry : e.getCases()) {
                        var caseDefn = entry.get2();
                        var body = translate(entry.get5());
                        var tag = caseDefn.getTag();
                        var names = entry.get3().map(d -> "L$" + d.getName());
                        var mutable = entry.get3().any(d -> d.isMutable());
                        var prefix = mutable ? "let " : "const ";
                        out.append("case " + tag + ":{");
                        if (!e.getTarget().getType().isSimpleUnion()) {
                            out.append(prefix + "[," + Str.join(",", names) + "]=");
                            target.emitBody(out);
                            out.append(";");
                        }
                        body.emitSet(out, tmpvar + "=");
                        out.append("break;");
                        out.append("}");
                    }
                    if (e.getFallback().isPresent()) {
                        var fallback = translate(e.getFallback().get());
                        out.append("default:{");
                        fallback.emitSet(out, tmpvar + "=");
                        out.append("}");
                    } else {
                        out.append("default:throw new Error(\"Invalid tag\");");
                    }
                    out.append("}");
                }, out -> out.append(tmpvar), true);
            }

            @Override
            public CJJSBlob2 visitSwitch(CJIRSwitch e, Void a) {
                var target = translate(e.getTarget());
                var tmpvar = varFactory.newName();
                return CJJSBlob2.withPrep(out -> {
                    target.emitPrep(out);
                    out.append("let " + tmpvar + ";");
                    out.append("switch(");
                    target.emitBody(out);
                    out.append("){");
                    for (var case_ : e.getCases()) {
                        var values = case_.get1().map(c -> {
                            var v = translate(c);
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
                            value.emitBody(out);
                            out.append(":");
                        }
                        out.append("{");
                        var body = translate(case_.get2());
                        body.emitSet(out, tmpvar + "=");
                        out.append("break;");
                        out.append("}");
                    }
                    out.append("default:");
                    if (e.getFallback().isPresent()) {
                        out.append("{");
                        var fallback = translate(e.getFallback().get());
                        fallback.emitSet(out, tmpvar + "=");
                        out.append("}");
                    } else {
                        out.append("throw new Error('Unhandled switch case');");
                    }
                    out.append("}");
                }, out -> out.append(tmpvar), true);
            }

            @Override
            public CJJSBlob2 visitLambda(CJIRLambda e, Void a) {
                var body = translate(e.getBody());
                return CJJSBlob2.simple(out -> {
                    out.append("(");
                    if (e.isAsync()) {
                        out.append("async");
                    }
                    out.append("(");
                    for (int i = 0; i < e.getParameters().size(); i++) {
                        if (i > 0) {
                            out.append(",");
                        }
                        out.append("L$" + e.getParameters().get(i).getName());
                    }
                    out.append(")=>");
                    if (body.isSimple()) {
                        body.emitBody(out);
                    } else {
                        out.append("{");
                        body.emitSet(out, "return ");
                        out.append("}");
                    }
                    out.append(")");
                }, false);
            }

            @Override
            public CJJSBlob2 visitReturn(CJIRReturn e, Void a) {
                var inner = translate(e.getExpression());
                return CJJSBlob2.withPrep(out -> {
                    inner.emitSet(out, "return ");
                }, out -> out.append("NORETURN()"), true);
            }

            @Override
            public CJJSBlob2 visitAwait(CJIRAwait e, Void a) {
                var inner = translate(e.getInner());
                return new CJJSBlob2(inner.getPrep(), out -> {
                    out.append("(");
                    out.addMark(e.getMark());
                    out.append("await ");
                    inner.emitBody(out);
                    out.append(")");
                }, false);
            }

            @Override
            public CJJSBlob2 visitThrow(CJIRThrow e, Void a) {
                var inner = translate(e.getExpression());
                var exctype = e.getExpression().getType();
                if (exctype.repr().equals("cj.Error")) {
                    return CJJSBlob2.withPrep(out -> inner.emitSet(out, "throw "), out -> out.append("undefined"),
                            true);
                } else {
                    var typeId = typeIdRegistry.getId(exctype);
                    requestNative.accept("wrapping-exception.js", e.getMark());
                    return CJJSBlob2.withPrep(out -> {
                        inner.emitPrep(out);
                        out.append("throw new WrappingException(" + typeId + ",");
                        inner.emitBody(out);
                        out.append(");");
                    }, out -> {
                        out.append("undefined");
                    }, true);
                }
            }

            @Override
            public CJJSBlob2 visitTry(CJIRTry e, Void a) {
                var tmpvar = varFactory.newName();
                var body = translate(e.getBody());
                var xclauses = e.getClauses().filter(c -> !c.get2().repr().equals("cj.Error"));
                var yclauses = e.getClauses().filter(c -> c.get2().repr().equals("cj.Error"));
                if (xclauses.size() > 0) {
                    requestNative.accept("wrapping-exception.js", e.getMark());
                }
                return CJJSBlob2.withPrep(out -> {
                    out.append("let " + tmpvar + ";");
                    out.append("try{");
                    body.emitSet(out, tmpvar + "=");
                    if (e.getClauses().size() > 0) {
                        out.append("}catch(w){");
                        // handle cj.Error clauses in the else branch
                        if (xclauses.size() > 0) {
                            out.append("if(w instanceof WrappingException){switch(w.typeId){");
                            for (int i = 0; i < xclauses.size(); i++) {
                                var clause = xclauses.get(i);
                                var exctype = clause.get2();
                                var typeId = typeIdRegistry.getId(exctype);
                                out.append("case " + typeId + ":{");
                                out.append("const " + translateTarget(clause.get1()) + "=w.data;");
                                var clauseBody = translate(clause.get3());
                                clauseBody.emitSet(out, tmpvar + "=");
                                out.append("break;}");
                            }
                            out.append("default:throw w}");
                            out.append("}else{");
                        } else {
                            out.append("{");
                        }
                        if (yclauses.isEmpty()) {
                            out.append("throw w;");
                        } else {
                            Assert.equals(yclauses.size(), 1);
                            var clause = yclauses.get(0);
                            out.append("if(w instanceof Error){");
                            out.append("const " + translateTarget(clause.get1()) + "=w;");
                            var clauseBody = translate(clause.get3());
                            clauseBody.emitSet(out, tmpvar + "=");
                            out.append("}else{throw w;}");
                        }
                        out.append("}");
                    }
                    out.append("}");
                    if (e.getFin().isPresent()) {
                        out.append("finally{");
                        translate(e.getFin().get()).emitDrop(out);
                        out.append("}");
                    }
                }, out -> {
                    out.append(tmpvar);
                }, true);
            }

            @Override
            public CJJSBlob2 visitTag(CJIRTag e, Void a) {
                var inner = translate(e.getTarget());
                if (e.getTarget().getType().isSimpleUnion()) {
                    return inner;
                } else {
                    return new CJJSBlob2(inner.getPrep(), out -> {
                        inner.emitBody(out);
                        out.append("[0]");
                    }, false);
                }
            }

            @Override
            public CJJSBlob2 visitJSBlob(CJIRJSBlob e, Void a) {
                var parts = e.getParts().map(p -> (p instanceof String) ? p : translate((CJIRExpression) p));
                var prep = joinPreps(parts.filter(p -> p instanceof CJJSBlob2).map(p -> ((CJJSBlob2) p).getPrep()));
                return new CJJSBlob2(prep, out -> {
                    out.append("(");
                    for (var part : parts) {
                        if (part instanceof String) {
                            out.append((String) part);
                        } else {
                            ((CJJSBlob2) part).emitBody(out);
                        }
                    }
                    out.append(")");
                }, false);
            }

            @Override
            public CJJSBlob2 visitIsSet(CJIRIsSet e, Void a) {
                if (e.getOwner().isPresent()) {
                    var owner = translate(e.getOwner().get());
                    return new CJJSBlob2(owner.getPrep(), out -> {
                        out.append("(");
                        owner.emitBody(out);
                        out.append("[" + e.getField().getIndex() + "]!==undefined)");
                    }, false);
                } else {
                    var owner = e.getOwnerType();
                    var field = e.getField();
                    var varName = CJJSTranslator2.getStaticFieldVarName(owner, field);
                    return CJJSBlob2.simplestr("(" + varName + "!==undefined)", false);
                }
            }
        }, null);
    }

    static Optional<Consumer<CJJSSink>> joinPreps(List<Optional<Consumer<CJJSSink>>> prepList) {
        if (prepList.all(p -> p.isEmpty())) {
            return Optional.empty();
        }
        var preps = prepList.flatMap(p -> p);
        return Optional.of(out -> {
            for (var prep : preps) {
                prep.accept(out);
            }
        });
    }

    static CJJSBlob2 translateParts(List<CJJSBlob2> args, String... parts) {
        Assert.equals(args.size() + 1, parts.length);
        return new CJJSBlob2(joinPreps(args.map(arg -> arg.getPrep())), out -> {
            for (int i = 0; i + 1 < parts.length; i++) {
                out.append(parts[i]);
                args.get(i).emitBody(out);
            }
            out.append(parts[parts.length - 1]);
        }, false);
    }

    static CJJSBlob2 translateOp(String prefix, String postfix, String op, List<CJJSBlob2> args) {
        return new CJJSBlob2(joinPreps(args.map(arg -> arg.getPrep())), out -> {
            out.append(prefix);
            for (int i = 0; i < args.size(); i++) {
                if (i > 0) {
                    out.append(op);
                }
                args.get(i).emitBody(out);
            }
            out.append(postfix);
        }, false);
    }

    static CJJSBlob2 translateCall(CJMark mark, String funcName, List<CJJSBlob2> args) {
        return new CJJSBlob2(joinPreps(args.map(arg -> arg.getPrep())), out -> {
            out.addMark(mark);
            out.append(funcName + "(");
            for (int i = 0; i < args.size(); i++) {
                if (i > 0) {
                    out.append(",");
                }
                args.get(i).emitBody(out);
            }
            out.append(")");
        }, false);
    }

    static CJJSBlob2 translateDynamicCall(CJMark mark, List<CJJSBlob2> args) {
        return new CJJSBlob2(joinPreps(args.map(arg -> arg.getPrep())), out -> {
            out.addMark(mark);
            out.append("(");
            args.get(0).emitBody(out);
            out.append(")(");
            for (int i = 1; i < args.size(); i++) {
                if (i > 1) {
                    out.append(",");
                }
                args.get(i).emitBody(out);
            }
            out.append(")");
        }, false);
    }

    String translateTarget(CJIRAssignmentTarget target) {
        return target.accept(new CJIRAssignmentTargetVisitor<String, Void>() {

            @Override
            public String visitName(CJIRNameAssignmentTarget t, Void a) {
                return "L$" + t.getName();
            }

            @Override
            public String visitTuple(CJIRTupleAssignmentTarget t, Void a) {
                var subtargets = t.getSubtargets();
                var sb = new StringBuilder();
                sb.append("[");
                for (int i = 0; i < subtargets.size(); i++) {
                    if (i > 0) {
                        sb.append(',');
                    }
                    sb.append(translateTarget(subtargets.get(i)));
                }
                sb.append("]");
                return sb.toString();
            }
        }, null);
    }

    private static boolean isOne(CJIRExpression expr) {
        if (expr instanceof CJIRLiteral) {
            var lit = (CJIRLiteral) expr;
            return lit.getRawText().equals("1");
        }
        return false;
    }
}
