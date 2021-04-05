package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.cj.ir.meta.CJIRTraitOrClassType;
import crossj.cj.ir.meta.CJIRType;

/**
 * CJIRMethodRef together with its type arguments
 */
public final class CJIRReifiedMethodRef {
    private final CJIRMethodRef methodRef;
    private final List<CJIRType> typeArgs;
    private final CJIRBinding binding;

    public CJIRReifiedMethodRef(CJIRMethodRef methodRef, List<CJIRType> typeArgs, CJIRBinding binding) {
        Assert.equals(methodRef.getMethod().getTypeParameters().size(), typeArgs.size());
        this.methodRef = methodRef;
        this.typeArgs = typeArgs;
        this.binding = binding;
    }

    public CJIRTraitOrClassType getOwner() {
        return methodRef.getOwner();
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

    public String getName() {
        return methodRef.getName();
    }
}
