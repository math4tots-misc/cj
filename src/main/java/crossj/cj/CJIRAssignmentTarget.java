package crossj.cj;

public abstract class CJIRAssignmentTarget extends CJIRNode<CJAstAssignmentTarget> {
    private final CJIRType targetType;

    CJIRAssignmentTarget(CJAstAssignmentTarget ast, CJIRType targetType) {
        super(ast);
        this.targetType = targetType;
    }

    public abstract <R, A> R accept(CJIRAssignmentTargetVisitor<R, A> visitor, A a);

    public final CJIRType getTargetType() {
        return targetType;
    }
}
