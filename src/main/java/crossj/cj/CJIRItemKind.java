package crossj.cj;

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
}
