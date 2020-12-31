package crossj.cj;

public final class CJIRVariableType extends CJIRType {
    private final CJIRTypeParameter declaration;

    CJIRVariableType(CJIRTypeParameter declaration) {
        this.declaration = declaration;
    }

    public String getName() {
        return declaration.getName();
    }

    @Override
    public String toString() {
        return getName();
    }
}
