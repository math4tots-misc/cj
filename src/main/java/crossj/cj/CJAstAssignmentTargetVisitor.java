package crossj.cj;

public abstract class CJAstAssignmentTargetVisitor<R, A> {
    public abstract R visitName(CJAstNameAssignmentTarget t, A a);
    public abstract R visitTuple(CJAstTupleAssignmentTarget t, A a);
}
