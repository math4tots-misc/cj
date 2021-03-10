package crossj.cj.js;

import java.util.function.BiConsumer;
import java.util.function.Consumer;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJError;
import crossj.cj.CJIRAssignment;
import crossj.cj.CJIRAssignmentTarget;
import crossj.cj.CJIRAssignmentTargetVisitor;
import crossj.cj.CJIRAugAssignKind;
import crossj.cj.CJIRAugmentedAssignment;
import crossj.cj.CJIRAwait;
import crossj.cj.CJIRBlock;
import crossj.cj.CJIRExpression;
import crossj.cj.CJIRExpressionVisitor;
import crossj.cj.CJIRFieldMethodInfo;
import crossj.cj.CJIRFor;
import crossj.cj.CJIRIf;
import crossj.cj.CJIRIfNull;
import crossj.cj.CJIRIs;
import crossj.cj.CJIRLambda;
import crossj.cj.CJIRListDisplay;
import crossj.cj.CJIRLiteral;
import crossj.cj.CJIRLogicalBinop;
import crossj.cj.CJIRLogicalNot;
import crossj.cj.CJIRMethodCall;
import crossj.cj.CJIRNameAssignmentTarget;
import crossj.cj.CJIRNullWrap;
import crossj.cj.CJIRReturn;
import crossj.cj.CJIRSwitch;
import crossj.cj.CJIRThrow;
import crossj.cj.CJIRTry;
import crossj.cj.CJIRTupleAssignmentTarget;
import crossj.cj.CJIRTupleDisplay;
import crossj.cj.CJIRVariableAccess;
import crossj.cj.CJIRVariableDeclaration;
import crossj.cj.CJIRWhen;
import crossj.cj.CJIRWhile;
import crossj.cj.CJJSSink;
import crossj.cj.CJMark;
import crossj.cj.CJToken;

final class CJJSExpressionTranslator2 {
    private final CJJSTempVarFactory varFactory;
    private final CJJSMethodNameRegistry methodNameRegistry;
    private final CJJSTypeBinding binding;
    private final Consumer<CJJSLLMethod> requestMethod;
    private final BiConsumer<String, CJMark> requestNative;

    CJJSExpressionTranslator2(CJJSTempVarFactory varFactory, CJJSMethodNameRegistry methodNameRegistry,
            CJJSTypeBinding binding, Consumer<CJJSLLMethod> requestMethod,
            BiConsumer<String, CJMark> requestNative) {
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
                var args = e.getArgs().map(arg -> translate(arg));
                var owner = binding.apply(e.getOwner());
                var reifiedMethodRef = e.getReifiedMethodRef();
                var llmethod = binding.translate(owner, reifiedMethodRef);

                var key = owner.getItem().getFullName() + "." + reifiedMethodRef.getName();

                var op = CJJSOps.OPS.getOrNull(key);
                if (op != null) {
                    var ctx = new CJJSOps.Context(key, binding, e, args, owner, reifiedMethodRef, llmethod,
                            requestMethod, requestNative);
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
                            return translateParts(args, "", "[" + fieldIndex + "]");
                        case "=":
                            return translateParts(args, "(", "[" + fieldIndex + "]=", ")");
                        case "+=":
                            return translateParts(args, "(", "[" + fieldIndex + "]+=", ")");
                        default:
                            throw new RuntimeException("Unrecognized kind " + fmi.getKind());
                        }
                    }
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
                return translateParts(List.of(translate(e.getLeft()), translate(e.getRight())), "(",
                        e.isAnd() ? "&&" : "||", ")");
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
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO_When");
            }

            @Override
            public CJJSBlob2 visitSwitch(CJIRSwitch e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO_Switch");
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
                }, out -> out.append("NORETURN"), true);
            }

            @Override
            public CJJSBlob2 visitAwait(CJIRAwait e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO_Await");
            }

            @Override
            public CJJSBlob2 visitThrow(CJIRThrow e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO_Throw");
            }

            @Override
            public CJJSBlob2 visitTry(CJIRTry e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO_Try");
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
