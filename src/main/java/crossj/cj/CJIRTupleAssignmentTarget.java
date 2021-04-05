package crossj.cj;

import crossj.base.List;
import crossj.cj.ast.CJAstAssignmentTarget;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRTupleAssignmentTarget extends CJIRAssignmentTarget {
    private final List<CJIRAssignmentTarget> subtargets;

    public CJIRTupleAssignmentTarget(CJAstAssignmentTarget ast, List<CJIRAssignmentTarget> subtargets, CJIRType targetType) {
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
