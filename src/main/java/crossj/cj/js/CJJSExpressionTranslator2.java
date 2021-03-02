package crossj.cj.js;

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
import crossj.cj.CJToken;

final class CJJSExpressionTranslator2 {
    private final CJJSTempVarFactory varFactory;
    // private final CJJSTypeBinding binding;

    CJJSExpressionTranslator2(CJJSTempVarFactory varFactory, CJJSTypeBinding binding) {
        this.varFactory = varFactory;
        // this.binding = binding;
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
                    out.append("}");
                }, out -> {
                    out.append(tmpvar);
                }, true);
            }

            @Override
            public CJJSBlob2 visitMethodCall(CJIRMethodCall e, Void a) {

                var args = e.getArgs().map(arg -> translate(arg));


                // regular call
                if (args.all(arg -> arg.isSimple())) {
                    // var reifiedMethodRef = e.getReifiedMethodRef();
                }

                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitVariableDeclaration(CJIRVariableDeclaration e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitVariableAccess(CJIRVariableAccess e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitAssignment(CJIRAssignment e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitAugmentedAssignment(CJIRAugmentedAssignment e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitLogicalNot(CJIRLogicalNot e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitLogicalBinop(CJIRLogicalBinop e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitIs(CJIRIs e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitNullWrap(CJIRNullWrap e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitListDisplay(CJIRListDisplay e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitTupleDisplay(CJIRTupleDisplay e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitIf(CJIRIf e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitIfNull(CJIRIfNull e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitWhile(CJIRWhile e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitFor(CJIRFor e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitWhen(CJIRWhen e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitSwitch(CJIRSwitch e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitLambda(CJIRLambda e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitReturn(CJIRReturn e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitAwait(CJIRAwait e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitThrow(CJIRThrow e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }

            @Override
            public CJJSBlob2 visitTry(CJIRTry e, Void a) {
                // TODO Auto-generated method stub
                return null;
            }
        }, null);
    }
}
