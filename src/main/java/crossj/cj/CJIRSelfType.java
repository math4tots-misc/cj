package crossj.cj;

import crossj.base.List;

public final class CJIRSelfType implements CJIRType {
    private final CJIRTrait selfTrait;

    CJIRSelfType(CJIRTrait selfTrait) {
        this.selfTrait = selfTrait;
    }

    @Override
    public <R, A> R accept(CJIRTypeVisitor<R, A> visitor, A a) {
        return visitor.visitSelf(this, a);
    }
    @Override
    public List<CJIRTrait> getTraits(CJMark... marks) {
        return List.of(selfTrait);
    }

    @Override
    public CJIRMethodRef findMethodOrNull(String shortName) {
        return selfTrait.findMethodOrNull(shortName);
    }

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof CJIRSelfType)) {
            return false;
        }
        var other = (CJIRSelfType) obj;
        return selfTrait.equals(other.selfTrait);
    }

    @Override
    public String toString() {
        return "Self";
    }
}
