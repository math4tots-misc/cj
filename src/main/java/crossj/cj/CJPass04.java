package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;

/**
 * Pass 4
 *
 * Resolve expressions
 */
public final class CJPass04 extends CJPassBaseEx {
    CJPass04(CJIRContext ctx) {
        super(ctx);
    }

    @Override
    void handleItem(CJIRItem item) {
        for (var member : item.getMembers()) {
            if (member instanceof CJIRMethod) {
                handleMethod((CJIRMethod) member);
            }
        }
    }

    private void handleMethod(CJIRMethod method) {
        if (method.getAst().getBody().isEmpty()) {
            return;
        }
        var bodyAst = method.getAst().getBody().get();
        var body = evalExpressionWithType(bodyAst, method.getReturnType());
        method.setBody(body);
    }

    private CJIRExpression evalExpression(CJAstExpression expression) {
        return evalExpressionEx(expression, Optional.empty());
    }

    private CJIRExpression evalExpressionWithType(CJAstExpression expression, CJIRType type) {
        return evalExpressionEx(expression, Optional.of(type));
    }

    private CJIRExpression evalExpressionEx(CJAstExpression expression, Optional<CJIRType> type) {
        var ir = expression.accept(new CJAstExpressionVisitor<CJIRExpression, Optional<CJIRType>>() {

            @Override
            public CJIRExpression visitLiteral(CJAstLiteral e, Optional<CJIRType> a) {
                switch (e.getKind()) {
                    case Unit: {
                        return new CJIRLiteral(e, ctx.getUnitType(), e.getRawText());
                    }
                    case Bool: {
                        return new CJIRLiteral(e, ctx.getBoolType(), e.getRawText());
                    }
                    case Int: {
                        return new CJIRLiteral(e, ctx.getIntType(), e.getRawText());
                    }
                    case Double: {
                        return new CJIRLiteral(e, ctx.getDoubleType(), e.getRawText());
                    }
                    case String: {
                        return new CJIRLiteral(e, ctx.getStringType(), e.getRawText());
                    }
                }
                throw CJError.of("TODO evalExpression-visitBlock", e.getMark());
            }

            @Override
            public CJIRExpression visitBlock(CJAstBlock e, Optional<CJIRType> a) {
                var exprs = e.getExpressions();
                if (exprs.size() == 0) {
                    return new CJIRLiteral(e, ctx.getUnitType(), "");
                }
                var newExprs = List.<CJIRExpression>of();
                for (int i = 0; i + 1 < exprs.size(); i++) {
                    newExprs.add(evalExpressionWithType(exprs.get(i), ctx.getUnitType()));
                }
                newExprs.add(evalExpressionWithType(exprs.last(), a.get()));

                return new CJIRBlock(e, newExprs.last().getType(), newExprs);
            }

            @Override
            public CJIRExpression visitMethodCall(CJAstMethodCall e, Optional<CJIRType> a) {
                if (e.getOwner().isEmpty()) {
                    throw CJError.of("TODO evalExpression-visitMethodCall instance", e.getMark());
                } else {
                    var ownerAst = e.getOwner().get();
                    var owner = lctx.evalTypeExpression(ownerAst);
                    var methodRef = owner.findMethod(e.getName());
                    var typeArgs = e.getTypeArgs().map(lctx::evalTypeExpression);
                }
                throw CJError.of("TODO evalExpression-visitMethodCall", e.getMark());
            }
        }, type);
        if (type.isPresent()) {
            var expectedType = type.get();
            var actualType = ir.getType();
            if (!expectedType.equals(actualType)) {
                throw CJError.of("Expected " + expectedType + " but got " + actualType, expression.getMark());
            }
        }
        return ir;
    }
}
