package crossj.cj;

public abstract class CJAstExpressionVisitor<R, A> {
    public abstract R visitLiteral(CJAstLiteral e, A a);
    public abstract R visitBlock(CJAstBlock e, A a);
    public abstract R visitMethodCall(CJAstMethodCall e, A a);
    public abstract R visitVariableDeclaration(CJAstVariableDeclaration e, A a);
    public abstract R visitVariableAccess(CJAstVariableAccess e, A a);
    public abstract R visitAssignment(CJAstAssignment e, A a);
    public abstract R visitAugmentedAssignment(CJAstAugmentedAssignment e, A a);
    public abstract R visitLogicalNot(CJAstLogicalNot e, A a);
    public abstract R visitLogicalBinop(CJAstLogicalBinop e, A a);
    public abstract R visitIs(CJAstIs e, A a);
    public abstract R visitNullWrap(CJAstNullWrap e, A a);
    public abstract R visitListDisplay(CJAstListDisplay e, A a);
    public abstract R visitTupleDisplay(CJAstTupleDisplay e, A a);
    public abstract R visitIf(CJAstIf e, A a);
    public abstract R visitIfNull(CJAstIfNull e, A a);
    public abstract R visitWhile(CJAstWhile e, A a);
    public abstract R visitFor(CJAstFor e, A a);
    public abstract R visitWhen(CJAstWhen e, A a);
    public abstract R visitSwitch(CJAstSwitch e, A a);
    public abstract R visitLambda(CJAstLambda e, A a);
    public abstract R visitReturn(CJAstReturn e, A a);
    public abstract R visitAwait(CJAstAwait e, A a);
    public abstract R visitThrow(CJAstThrow e, A a);
    public abstract R visitTry(CJAstTry e, A a);
}
