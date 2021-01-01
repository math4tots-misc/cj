package crossj.cj;

import crossj.base.List;

public interface CJIRType {
    <R, A> R accept(CJIRTypeVisitor<R, A> visitor, A a);

    default CJMark getMarkOrDefault(CJMark defaultMark) {
        return defaultMark;
    }

    /**
     * All directly declared traits for this type.
     * @param marks
     * @return
     */
    List<CJIRTrait> getTraits(CJMark... marks);

    default CJIRType apply(CJIRBinding binding, CJMark... marks) {
        return binding.apply(this, marks);
    }
}
