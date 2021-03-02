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
import crossj.cj.CJIRAugmentedAssignment;
import crossj.cj.CJIRAwait;
import crossj.cj.CJIRBlock;
import crossj.cj.CJIRExpression;
import crossj.cj.CJIRExpressionVisitor;
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
    private final Consumer<CJJSReifiedMethod> requestMethod;
    private final BiConsumer<String, CJMark> requestNative;

    CJJSExpressionTranslator2(CJJSTempVarFactory varFactory, CJJSMethodNameRegistry methodNameRegistry,
            CJJSTypeBinding binding, Consumer<CJJSReifiedMethod> requestMethod,
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
                var reifiedMethod = binding.translate(owner, reifiedMethodRef);

                var key = owner.getItem().getFullName() + "." + reifiedMethodRef.getName();
                switch (key) {
                    case "cj.Int.__pos":
                        return args.get(0);
                    case "cj.Int.__neg":
                        return translateOp("(-", ")", "", args);
                    case "cj.Int.__invert":
                        return translateOp("(~", ")", "", args);
                    case "cj.Int.__add":
                        return translateOp("(", ")", "+", args);
                    case "cj.Int.__sub":
                        return translateOp("(", ")", "-", args);
                    case "cj.Int.__mul":
                        return translateOp("(", ")", "*", args);
                    case "cj.Int.__truncdiv":
                        return translateOp("((", ")|0)", "/", args);
                    case "cj.Int.__div":
                        return translateOp("(", ")", "/", args);
                    case "cj.Int.__rem":
                        return translateOp("(", ")", "%", args);
                    case "cj.Int.__eq":
                        return translateOp("(", ")", "===", args);
                    case "cj.Int.toBool":
                        return args.get(0);
                    case "cj.Double._fromInt":
                        return translateOp("((", ")|0)", "", args);
                    case "cj.String.__add":
                        Assert.equals(args.size(), 2);
                        Assert.equals(reifiedMethodRef.getTypeArgs().size(), 1);
                        var argtype = binding.apply(reifiedMethodRef.getTypeArgs().get(0));
                        switch (argtype.toString()) {
                            case "cj.Bool":
                            case "cj.Int":
                            case "cj.Double":
                            case "cj.String":
                                return translateOp("(", ")", "+", args);
                            default:
                                break;
                        }
                        break;
                    case "cj.String.__eq":
                        return translateOp("(", ")", "===", args);
                    case "cj.List.size":
                        return translateOp("", ".length", "", args);
                    case "cj.Fn0.call":
                    case "cj.Fn1.call":
                    case "cj.Fn2.call":
                    case "cj.Fn3.call":
                    case "cj.Fn4.call":
                        return translateDynamicCall(e.getMark(), args);
                    case "cj.IO.println":
                        return translateCall(e.getMark(), "console.log", args);
                    case "cj.IO.eprintln":
                        return translateCall(e.getMark(), "console.error", args);
                }

                var isNative = reifiedMethodRef.getOwner().isNative();
                if (isNative) {
                    requestNative.accept(key + ".js", e.getMark());
                    return translateCall(e.getMark(), key.replace(".", "$"), args);
                }

                requestMethod.accept(reifiedMethod);
                var jsMethodName = methodNameRegistry.nameForReifiedMethod(reifiedMethod);

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
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitLogicalNot(CJIRLogicalNot e, Void a) {
                return translateOp("(!", ")", "", List.of(translate(e.getInner())));
            }

            @Override
            public CJJSBlob2 visitLogicalBinop(CJIRLogicalBinop e, Void a) {
                return translateOp("(", ")", e.isAnd() ? "&&" : "||",
                        List.of(translate(e.getLeft()), translate(e.getRight())));
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
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitWhile(CJIRWhile e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitFor(CJIRFor e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitWhen(CJIRWhen e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitSwitch(CJIRSwitch e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitLambda(CJIRLambda e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitReturn(CJIRReturn e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitAwait(CJIRAwait e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitThrow(CJIRThrow e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitTry(CJIRTry e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }
        }, null);
    }

    Optional<Consumer<CJJSSink>> joinPreps(List<Optional<Consumer<CJJSSink>>> prepList) {
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

    CJJSBlob2 translateOp(String prefix, String postfix, String op, List<CJJSBlob2> args) {
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

    CJJSBlob2 translateCall(CJMark mark, String funcName, List<CJJSBlob2> args) {
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

    CJJSBlob2 translateDynamicCall(CJMark mark, List<CJJSBlob2> args) {
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
}
