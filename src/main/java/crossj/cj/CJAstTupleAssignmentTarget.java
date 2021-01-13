package crossj.cj;

import crossj.base.List;

public class CJAstTupleAssignmentTarget extends CJAstAssignmentTarget {
    private final List<CJAstAssignmentTarget> subtargets;

    CJAstTupleAssignmentTarget(CJMark mark, List<CJAstAssignmentTarget> subtargets) {
        super(mark);
        this.subtargets = subtargets;
    }

    public List<CJAstAssignmentTarget> getSubtargets() {
        return subtargets;
    }

    @Override
    public <R, A> R accept(CJAstAssignmentTargetVisitor<R, A> visitor, A a) {
        return visitor.visitTuple(this, a);
    }
}
