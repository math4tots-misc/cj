package crossj.cj;

public abstract class CJAstAssignmentTarget extends CJAstNode {
    CJAstAssignmentTarget(CJMark mark) {
        super(mark);
    }

    public abstract <R, A> R accept(CJAstAssignmentTargetVisitor<R, A> visitor, A a);
}
