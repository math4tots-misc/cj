package crossj.cj;

public enum CJIRItemKind {
    Class,
    Union,
    Trait,
    Interface;

    public boolean isTraitKind() {
        return this == Trait;
    }

    public boolean isTypeKind() {
        return !isTraitKind();
    }

    public boolean isUnion() {
        return this == Union;
    }

    public boolean isInterface() {
        return this == Interface;
    }
}
