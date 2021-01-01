package crossj.cj;

import crossj.base.List;

public final class CJIRVariableType implements CJIRType {
    private final CJIRTypeParameter declaration;

    CJIRVariableType(CJIRTypeParameter declaration) {
        this.declaration = declaration;
    }

    public String getName() {
        return declaration.getName();
    }

    @Override
    public List<CJIRTrait> getTraits(CJMark... marks) {
        return declaration.getTraits();
    }

    @Override
    public String toString() {
        return getName();
    }

    @Override
    public <R, A> R accept(CJIRTypeVisitor<R, A> visitor, A a) {
        return visitor.visitVariable(this, a);
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJIRVariableType)) {
            return false;
        }
        var other = (CJIRVariableType) obj;
        return declaration == other.declaration;
    }
}
