package crossj.cj.js2;

import crossj.cj.ir.CJIRMethod;
import crossj.cj.ir.meta.CJIRClassType;
import crossj.cj.ir.meta.CJIRTraitOrClassType;

/**
 * A CJIRMethod together with a type-binding and its reified owner.
 *
 * 'low-level' CJIRReifiedMethodRef
 */
public final class CJJSLLMethod {
    private final CJIRTraitOrClassType declaringTraitOrClass;
    private final CJIRMethod method;
    private final CJJSTypeBinding binding;

    public CJJSLLMethod(CJIRTraitOrClassType declaringTraitOrClass, CJIRMethod method, CJJSTypeBinding binding) {
        this.declaringTraitOrClass = declaringTraitOrClass;
        this.method = method;
        this.binding = binding;
    }

    public CJIRTraitOrClassType getDeclaringTraitOrClass() {
        return declaringTraitOrClass;
    }

    public CJIRClassType getFinalOwnerType() {
        return binding.getSelfType();
    }

    public CJIRMethod getMethod() {
        return method;
    }

    public CJJSTypeBinding getBinding() {
        return binding;
    }

    public String getId() {
        return getFinalOwnerType().repr() + "." + method.getName()
                + (binding.isEmpty() ? "" : "<" + binding.getIdStr());
    }
}
