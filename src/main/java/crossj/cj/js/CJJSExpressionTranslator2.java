package crossj.cj.js;

import java.util.function.BiConsumer;
import java.util.function.Consumer;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJError;
import crossj.cj.CJIRAssignment;
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
import crossj.cj.CJIRNullWrap;
import crossj.cj.CJIRReturn;
import crossj.cj.CJIRSwitch;
import crossj.cj.CJIRThrow;
import crossj.cj.CJIRTry;
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

                var isNative = reifiedMethodRef.getOwner().isNative();

                if (isNative) {
                    var key = reifiedMethodRef.getOwner().getItem().getFullName() + "." + reifiedMethodRef.getName();
                    switch (key) {
                        case "cj.Assert.equal": {
                            Assert.equals(args.size(), 2);
                            Assert.equals(reifiedMethodRef.getTypeArgs().size(), 1);
                            var argtype = binding.apply(reifiedMethodRef.getTypeArgs().get(0));
                            switch (argtype.toString()) {
                                case "cj.Bool":
                                case "cj.Int":
                                case "cj.Double":
                                case "cj.String":
                                    requestNative.accept("cj.Assert.eq0.js", e.getMark());
                                    return new CJJSBlob2(joinPreps(args.map(arg -> arg.getPrep())), out -> {
                                        out.append("asserteq0(");
                                        args.get(0).emitBody(out);
                                        out.append(",");
                                        args.get(1).emitBody(out);
                                        out.append(")");
                                    }, false);
                                default:
                                    break;
                                    // throw CJError.of("Unsupported Assert.equal type " + argtype.toString(),
                                    //         e.getMark());
                            }
                            break;
                        }
                        case "cj.Int.__add": return translateBinop("+", args);
                        case "cj.Int.__mul": return translateBinop("*", args);
                    }
                    // throw CJError.of("Unrecognized native method " + key, e.getMark());
                }

                requestMethod.accept(reifiedMethod);
                var jsMethodName = methodNameRegistry.nameForReifiedMethod(reifiedMethod);

                // regular call
                if (args.all(arg -> arg.isSimple())) {
                    return CJJSBlob2.simple(out -> {
                        out.addMark(e.getMark());
                        out.append(jsMethodName + "(");
                        for (int i = 0; i < args.size(); i++) {
                            if (i > 0) {
                                out.append(",");
                            }
                            args.get(i).emitBody(out);
                        }
                        out.append(")");
                    }, false);
                }

                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitVariableDeclaration(CJIRVariableDeclaration e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitVariableAccess(CJIRVariableAccess e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitAssignment(CJIRAssignment e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitAugmentedAssignment(CJIRAugmentedAssignment e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitLogicalNot(CJIRLogicalNot e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitLogicalBinop(CJIRLogicalBinop e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitIs(CJIRIs e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitNullWrap(CJIRNullWrap e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitListDisplay(CJIRListDisplay e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitTupleDisplay(CJIRTupleDisplay e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
            }

            @Override
            public CJJSBlob2 visitIf(CJIRIf e, Void a) {
                // TODO Auto-generated method stub
                return CJJSBlob2.pure("TODO");
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

    CJJSBlob2 translateBinop(String op, List<CJJSBlob2> args) {
        return new CJJSBlob2(joinPreps(args.map(arg -> arg.getPrep())), out -> {
            out.append("(");
            for (int i = 0; i < args.size(); i++) {
                if (i > 0) {
                    out.append(op);
                }
                args.get(i).emitBody(out);
            }
            out.append(")");
        }, false);
    }
}
