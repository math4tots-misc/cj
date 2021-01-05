package crossj.cj;

public abstract class CJIRExpressionVisitor<R, A> {
    public abstract R visitLiteral(CJIRLiteral e, A a);
    public abstract R visitBlock(CJIRBlock e, A a);
    public abstract R visitMethodCall(CJIRMethodCall e, A a);
    public abstract R visitVariableDeclaration(CJIRVariableDeclaration e, A a);
    public abstract R visitVariableAccess(CJIRVariableAccess e, A a);
    public abstract R visitAssignment(CJIRAssignment e, A a);
    public abstract R visitLogicalNot(CJIRLogicalNot e, A a);
    public abstract R visitUnion(CJIRUnion e, A a);
    public abstract R visitLambda(CJIRLambda e, A a);
}
