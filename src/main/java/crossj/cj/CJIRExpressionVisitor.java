package crossj.cj;

public abstract class CJIRExpressionVisitor<R, A> {
    public abstract R visitLiteral(CJIRLiteral e, A a);
    public abstract R visitBlock(CJIRBlock e, A a);
    public abstract R visitMethodCall(CJIRMethodCall e, A a);
}
