package crossj.cj;

public final class CJIRMethodRef {
    private final CJIRTraitOrClassType owner;
    private final CJIRMethod method;

    CJIRMethodRef(CJIRTraitOrClassType owner, CJIRMethod method) {
        this.owner = owner;
        this.method = method;
    }

    public CJIRTraitOrClassType getOwner() {
        return owner;
    }

    public CJIRMethod getMethod() {
        return method;
    }
}
