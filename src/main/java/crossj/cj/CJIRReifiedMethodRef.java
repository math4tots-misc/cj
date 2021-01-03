package crossj.cj;

import crossj.base.List;

/**
 * CJIRMethodRef together with its type arguments
 */
public final class CJIRReifiedMethodRef {
    private final CJIRMethodRef methodRef;
    private final List<CJIRType> typeArgs;
    private final CJIRBinding binding;

    CJIRReifiedMethodRef(CJIRMethodRef methodRef, List<CJIRType> typeArgs, CJIRBinding binding) {
        this.methodRef = methodRef;
        this.typeArgs = typeArgs;
        this.binding = binding;
    }

    public CJIRMethodRef getMethodRef() {
        return methodRef;
    }

    public List<CJIRType> getTypeArgs() {
        return typeArgs;
    }

    public CJIRBinding getBinding() {
        return binding;
    }

    public List<CJIRType> getParameterTypes() {
        return methodRef.getMethod().getParameters().map(p -> p.getVariableType().apply(binding));
    }

    public CJIRType getReturnType() {
        return methodRef.getMethod().getReturnType().apply(binding);
    }
}
