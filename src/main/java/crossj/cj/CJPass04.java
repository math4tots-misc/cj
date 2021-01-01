package crossj.cj;

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
        return expression.accept(new CJAstExpressionVisitor<CJIRExpression, Optional<CJIRType>>(){

            @Override
            public CJIRExpression visitLiteral(CJAstLiteral e, Optional<CJIRType> a) {
                throw CJError.of("TODO evalExpression-visitLiteral", e.getMark());
            }

            @Override
            public CJIRExpression visitBlock(CJAstBlock e, Optional<CJIRType> a) {
                throw CJError.of("TODO evalExpression-visitBlock", e.getMark());
            }

            @Override
            public CJIRExpression visitMethodCall(CJAstMethodCall e, Optional<CJIRType> a) {
                throw CJError.of("TODO evalExpression-visitMethodCall", e.getMark());
            }
        }, type);
    }
}
