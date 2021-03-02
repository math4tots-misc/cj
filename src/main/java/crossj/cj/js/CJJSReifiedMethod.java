package crossj.cj.js;

import crossj.cj.CJIRMethod;

/**
 * A CJIRMethod together with a type-binding and its reified owner.
 */
public final class CJJSReifiedMethod {
    private final CJJSReifiedType owner;
    private final CJIRMethod method;
    private final CJJSTypeBinding binding;

    public CJJSReifiedMethod(CJJSReifiedType owner, CJIRMethod method, CJJSTypeBinding binding) {
        this.owner = owner;
        this.method = method;
        this.binding = binding;
    }

    public CJJSReifiedType getOwner() {
        return owner;
    }

    public CJIRMethod getMethod() {
        return method;
    }

    public CJJSTypeBinding getBinding() {
        return binding;
    }

    public String getId() {
        return owner.toString() + "." + method.getName() + (binding.isEmpty() ? "" : "<" + binding.toString());
    }
}
