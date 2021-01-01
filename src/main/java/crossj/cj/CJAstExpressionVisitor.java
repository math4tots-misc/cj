package crossj.cj;

public abstract class CJAstExpressionVisitor<R, A> {
    public abstract R visitLiteral(CJAstLiteral e, A a);
    public abstract R visitBlock(CJAstBlock e, A a);
    public abstract R visitMethodCall(CJAstMethodCall e, A a);
}
