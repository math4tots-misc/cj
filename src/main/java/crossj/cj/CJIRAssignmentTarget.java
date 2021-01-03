package crossj.cj;

public abstract class CJIRAssignmentTarget extends CJIRNode<CJAstAssignmentTarget> {
    CJIRAssignmentTarget(CJAstAssignmentTarget ast) {
        super(ast);
    }

    public abstract <R, A> R accept(CJIRAssignmentTargetVisitor<R, A> visitor, A a);

    public abstract CJIRType getTargetType();
}
