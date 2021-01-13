package crossj.cj;

import crossj.base.List;

public final class CJIRTupleAssignmentTarget extends CJIRAssignmentTarget {
    private final List<CJIRAssignmentTarget> subtargets;

    CJIRTupleAssignmentTarget(CJAstAssignmentTarget ast, List<CJIRAssignmentTarget> subtargets, CJIRType targetType) {
        super(ast, targetType);
        this.subtargets = subtargets;
    }

    public List<CJIRAssignmentTarget> getSubtargets() {
        return subtargets;
    }

    @Override
    public <R, A> R accept(CJIRAssignmentTargetVisitor<R, A> visitor, A a) {
        return visitor.visitTuple(this, a);
    }
}
