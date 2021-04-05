package crossj.cj.ast;

import crossj.cj.CJMark;

public abstract class CJAstAssignmentTarget extends CJAstNode {
    public CJAstAssignmentTarget(CJMark mark) {
        super(mark);
    }

    public abstract <R, A> R accept(CJAstAssignmentTargetVisitor<R, A> visitor, A a);
}
