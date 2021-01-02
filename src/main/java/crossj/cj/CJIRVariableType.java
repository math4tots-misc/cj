package crossj.cj;

import crossj.base.List;

public final class CJIRVariableType implements CJIRType {
    private final CJIRTypeParameter declaration;
    private final List<CJIRTrait> additionalTraits;

    CJIRVariableType(CJIRTypeParameter declaration, List<CJIRTrait> additionalTraits) {
        this.declaration = declaration;
        this.additionalTraits = additionalTraits;
    }

    public String getName() {
        return declaration.getName();
    }

    @Override
    public List<CJIRTrait> getTraits(CJMark... marks) {
        return List.join(declaration.getTraits(), additionalTraits);
    }

    @Override
    public CJIRMethodRef findMethodOrNull(String shortName) {
        for (var trait : getTraits()) {
            var methodRef = trait.findMethodOrNull(shortName);
            if (methodRef != null) {
                return methodRef;
            }
        }
        return null;
    }

    public List<CJIRTrait> getAdditionalTraits() {
        return additionalTraits;
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
