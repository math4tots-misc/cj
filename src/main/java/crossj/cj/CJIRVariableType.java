package crossj.cj;

import crossj.base.List;
import crossj.base.Pair;
import crossj.cj.ir.meta.CJIRTrait;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRVariableType implements CJIRType {
    private final CJIRTypeParameter declaration;
    private final List<CJIRTrait> additionalTraits;

    public CJIRVariableType(CJIRTypeParameter declaration, List<CJIRTrait> additionalTraits) {
        this.declaration = declaration;
        this.additionalTraits = additionalTraits;
    }

    public CJIRTypeParameter getDeclaration() {
        return declaration;
    }

    public String getName() {
        return declaration.getName();
    }

    @Override
    public List<CJIRTrait> getTraits() {
        return List.join(declaration.getTraits(), additionalTraits);
    }

    public boolean isItemLevel() {
        return declaration.isItemLevel();
    }

    public boolean isMethodLevel() {
        return declaration.isMethodLevel();
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
        throw new Error("Use CJIRType.toRawQualifiedName() instead");
    }

    @Override
    public String toRawQualifiedName() {
        return getName();
    }

    @Override
    public String repr() {
        return getName();
    }

    @Override
    public boolean isAbsoluteType() {
        return false;
    }

    @Override
    public <R, A> R accept(CJIRTypeVisitor<R, A> visitor, A a) {
        return visitor.visitVariable(this, a);
    }

    @Override
    public int hashCode() {
        return Pair.of(getClass(), declaration.getName()).hashCode();
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJIRVariableType)) {
            return false;
        }
        var other = (CJIRVariableType) obj;
        return declaration == other.declaration;
    }

    @Override
    public String getImplicitMethodNameForTypeOrNull(CJIRType type) {
        for (var trait : getTraits()) {
            var methodName = trait.getImplicitMethodNameForTypeOrNull(type);
            if (methodName != null) {
                return methodName;
            }
        }
        return null;
    }
}
