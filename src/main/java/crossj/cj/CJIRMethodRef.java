package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;

/**
 * CJIRMethod together with the CJIRTraitOrClassType that contains the method's
 * definition.
 */
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

    public String getName() {
        return method.getName();
    }

    public CJMark getMark() {
        return method.getMark();
    }

    public CJIRBinding getBinding(CJIRType selfType, List<CJIRType> args) {
        var typeParameters = method.getTypeParameters();
        Assert.equals(typeParameters.size(), args.size());
        var binding = owner.getBinding();
        for (int i = 0; i < args.size(); i++) {
            binding.put(typeParameters.get(i).getName(), args.get(i));
        }
        return new CJIRBinding(selfType, binding.getMap());
    }
}
