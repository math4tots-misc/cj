package crossj.cj;

public final class CJIRNameAssignmentTarget extends CJIRAssignmentTarget implements CJIRLocalVariableDeclaration {
    private final boolean mutable;
    private final String name;
    private final CJIRType variableType;

    CJIRNameAssignmentTarget(CJAstAssignmentTarget ast, boolean mutable, String name, CJIRType variableType) {
        super(ast);
        this.mutable = mutable;
        this.name = name;
        this.variableType = variableType;
    }

    @Override
    public boolean isMutable() {
        return mutable;
    }

    @Override
    public String getName() {
        return name;
    }

    @Override
    public CJIRType getVariableType() {
        return variableType;
    }

    @Override
    public <R, A> R accept(CJIRAssignmentTargetVisitor<R, A> visitor, A a) {
        return visitor.visitName(this, a);
    }

    @Override
    public CJIRType getTargetType() {
        return variableType;
    }
}
