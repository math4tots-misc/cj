package crossj.cj;

public final class CJAstNameAssignmentTarget extends CJAstAssignmentTarget {
    private final String name;

    CJAstNameAssignmentTarget(CJMark mark, String name) {
        super(mark);
        this.name = name;
    }

    public String getName() {
        return name;
    }

    @Override
    public <R, A> R accept(CJAstAssignmentTargetVisitor<R, A> visitor, A a) {
        return visitor.visitName(this, a);
    }
}
