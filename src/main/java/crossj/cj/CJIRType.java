package crossj.cj;

import crossj.base.List;
import crossj.base.Repr;

public interface CJIRType {

    <R, A> R accept(CJIRTypeVisitor<R, A> visitor, A a);

    /**
     * All directly declared traits for this type.
     * @param marks
     * @return
     */
    List<CJIRTrait> getTraits();

    default CJIRType apply(CJIRBinding binding, CJMark... marks) {
        return binding.apply(this, marks);
    }

    CJIRMethodRef findMethodOrNull(String shortName);

    default CJIRMethodRef findMethod(String shortName, CJMark... marks) {
        var methodRef = findMethodOrNull(shortName);
        if (methodRef == null) {
            throw CJError.of("Method " + Repr.of(shortName) + " not found in " + this, marks);
        }
        return methodRef;
    }

    default boolean isUnionType() {
        return false;
    }

    default boolean isListType() {
        return false;
    }

    default boolean isPromiseType() {
        return false;
    }

    default boolean isUnitType() {
        return toString().equals("cj.Unit");
    }

    default boolean isNoReturnType() {
        return toString().equals("cj.NoReturn");
    }

    default boolean isFunctionType() {
        return false;
    }

    default boolean implementsTrait(CJIRTrait trait) {
        for (var subtrait : getTraits()) {
            if (subtrait.extendsTrait(trait)) {
                return true;
            }
        }
        return false;
    }

    default CJIRTrait getImplementingTraitByItemOrNull(CJIRItem item) {
        for (var trait : getTraits()) {
            var ret = trait.getImplementingTraitByItemOrNull(item);
            if (ret != null) {
                return ret;
            }
        }
        return null;
    }
}
