package crossj.cj.js2;

import crossj.cj.ir.CJIRMethod;
import crossj.cj.ir.meta.CJIRClassType;

/**
 * A CJIRMethod together with a type-binding and its reified owner.
 *
 * 'low-level' CJIRReifiedMethodRef
 */
public final class CJJSLLMethod {
    private final CJIRClassType owner;
    private final CJIRMethod method;
    private final CJJSTypeBinding binding;

    public CJJSLLMethod(CJIRClassType owner, CJIRMethod method, CJJSTypeBinding binding) {
        this.owner = owner;
        this.method = method;
        this.binding = binding;
    }

    public CJIRClassType getOwner() {
        return owner;
    }

    public CJIRMethod getMethod() {
        return method;
    }

    public CJJSTypeBinding getBinding() {
        return binding;
    }

    public String getId() {
        return owner.repr() + "." + method.getName() + (binding.isEmpty() ? "" : "<" + binding.getIdStr());
    }
}
