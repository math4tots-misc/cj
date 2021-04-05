package crossj.cj.ir;

import crossj.base.Assert;
import crossj.base.List;
import crossj.cj.CJError;
import crossj.cj.CJMark;
import crossj.cj.ir.meta.CJIRTraitOrClassType;
import crossj.cj.ir.meta.CJIRType;

/**
 * CJIRMethod together with the CJIRTraitOrClassType that contains the method's
 * definition.
 */
public final class CJIRMethodRef {
    private final CJIRTraitOrClassType owner;
    private final CJIRMethod method;
    private boolean allConditionsCache = false;

    public CJIRMethodRef(CJIRTraitOrClassType owner, CJIRMethod method) {
        this.owner = owner;
        this.method = method;
    }

    public CJIRTraitOrClassType getOwner() {
        return owner;
    }

    public CJIRMethod getMethod() {
        return method;
    }

    public boolean isGeneric() {
        return method.isGeneric();
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
        return getPartialBinding(selfType, args);
    }

    public CJIRReifiedMethodRef reify(CJIRType selfType, List<CJIRType> args) {
        var binding = getBinding(selfType, args);
        return new CJIRReifiedMethodRef(this, args, binding);
    }

    public CJIRBinding getPartialBinding(CJIRType selfType, List<CJIRType> args, CJMark... marks) {
        var typeParameters = method.getTypeParameters();
        if (args.size() > typeParameters.size()) {
            throw CJError.of(owner.getItem().getFullName() + "." + method.getName() + " expectesd "
                    + typeParameters.size() + " type parameters but got " + args.size(), marks);
        }
        Assert.that(args.size() <= typeParameters.size());
        var binding = owner.getBindingWithSelfType(selfType);
        for (int i = 0; i < args.size(); i++) {
            binding.put(typeParameters.get(i).getName(), args.get(i));
        }
        return binding;
    }

    public boolean hasImpl() {
        return method.hasImpl();
    }

    /**
     * Checks whether all conditions on the method are satisfied.
     *
     * This is used to determine whether this method actually "exists" for the given
     * owner type.
     */
    public boolean satisfiesAllConditions() {
        if (!allConditionsCache) {
            allConditionsCache = method.getConditions().all(cond -> cond.isSatisfied(owner.getBinding()));
        }
        return allConditionsCache;
    }
}
