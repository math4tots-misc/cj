package crossj.cj;

import crossj.cj.ast.CJAstAssignmentTarget;

public final class CJIRNameAssignmentTarget extends CJIRAssignmentTarget implements CJIRLocalVariableDeclaration {
    private final boolean mutable;
    private final String name;

    CJIRNameAssignmentTarget(CJAstAssignmentTarget ast, boolean mutable, String name, CJIRType variableType) {
        super(ast, variableType);
        this.mutable = mutable;
        this.name = name;
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
        return getTargetType();
    }

    @Override
    public <R, A> R accept(CJIRAssignmentTargetVisitor<R, A> visitor, A a) {
        return visitor.visitName(this, a);
    }
}
