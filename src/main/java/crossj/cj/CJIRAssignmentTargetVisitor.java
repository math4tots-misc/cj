package crossj.cj;

public abstract class CJIRAssignmentTargetVisitor<R, A> {
    public abstract R visitName(CJIRNameAssignmentTarget t, A a);
}