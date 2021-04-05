package crossj.cj.ir;

public enum CJIRItemKind {
    Class,
    Union,
    Trait;

    public boolean isTraitKind() {
        return this == Trait;
    }

    public boolean isTypeKind() {
        return !isTraitKind();
    }

    public boolean isUnion() {
        return this == Union;
    }
}
