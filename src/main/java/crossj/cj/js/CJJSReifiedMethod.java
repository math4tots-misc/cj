package crossj.cj.js;

import crossj.cj.CJIRClassType;
import crossj.cj.CJIRMethod;

/**
 * A CJIRMethod together with a type-binding and its reified owner.
 */
public final class CJJSReifiedMethod {
    private final CJIRClassType owner;
    private final CJIRMethod method;
    private final CJJSTypeBinding binding;

    public CJJSReifiedMethod(CJIRClassType owner, CJIRMethod method, CJJSTypeBinding binding) {
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
        return owner.repr() + "." + method.getName() + (binding.isEmpty() ? "" : "<" + binding.toString());
    }
}
