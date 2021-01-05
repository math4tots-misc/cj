package crossj.cj;

public abstract class CJAstExpressionVisitor<R, A> {
    public abstract R visitLiteral(CJAstLiteral e, A a);
    public abstract R visitBlock(CJAstBlock e, A a);
    public abstract R visitMethodCall(CJAstMethodCall e, A a);
    public abstract R visitVariableDeclaration(CJAstVariableDeclaration e, A a);
    public abstract R visitVariableAccess(CJAstVariableAccess e, A a);
    public abstract R visitAssignment(CJAstAssignment e, A a);
    public abstract R visitLogicalNot(CJAstLogicalNot e, A a);
    public abstract R visitUnion(CJAstUnion e, A a);
    public abstract R visitLambda(CJAstLambda e, A a);
}
