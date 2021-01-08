package crossj.cj;

import crossj.base.Func1;
import crossj.base.List;
import crossj.base.Set;

public abstract class CJIRContextBase {

    static void walkTraits(CJIRItem item, Func1<Void, CJIRTrait> f) {
        var stack = item.toTraitOrClassType().getTraits();
        var seenTraits = Set.of(item.getFullName());
        seenTraits.addAll(stack.map(t -> t.getItem().getFullName()));
        while (stack.size() > 0) {
            var trait = stack.pop();
            f.apply(trait);
            for (var subtrait : trait.getTraits()) {
                var subtraitName = subtrait.getItem().getFullName();
                if (!seenTraits.contains(subtraitName)) {
                    seenTraits.add(subtraitName);
                    stack.add(subtrait);
                }
            }
        }
    }

    abstract CJIRContext getGlobal();

    public void validateMainItem(CJIRItem item, CJMark... marks) {
        if (item.getTypeParameters().size() > 0) {
            throw CJError.of("Items with type parameters may not be run as main", marks);
        }
        var method = item.getMethodOrNull("main");
        if (method == null) {
            throw CJError.of(item.getFullName() + " does not have a main method", item.getMark());
        }
        if (method.getTypeParameters().size() > 0 || method.getParameters().size() > 0) {
            throw CJError.of("Main methods cannot have type or value parameters", method.getMark());
        }
    }

    /**
     * Checks that the given type arguments are valid for the given item.
     */
    void checkItemArgs(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        checkItemArgc(item, args, marks);
        var binding = item.getBinding(args);
        var typeParameters = item.getTypeParameters();
        for (int i = 0; i < args.size(); i++) {
            var typeParameter = typeParameters.get(i);
            var arg = args.get(i);
            checkTypeArg(arg, marks);
            for (var subtrait : typeParameter.getTraits().map(t -> t.apply(binding, marks))) {
                if (!implementsTrait(arg, subtrait)) {
                    throw CJError.of(arg + " does not implement required trait " + subtrait, marks);
                }
            }
        }
    }

    private void checkTypeArg(CJIRType arg, CJMark... marks) {
        if (arg.isNullableType()) {
            throw CJError.of("Nullable types may not be used as a type argument", marks);
        }
    }

    void checkItemArgc(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        var expected = item.getTypeParameters().size();
        var actual = args.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " type args but got " + actual, marks);
        }
    }

    CJIRReifiedMethodRef checkMethodTypeArgs(CJIRType selfType, CJIRMethodRef methodRef, List<CJIRType> args,
            CJMark... marks) {
        checkMethodTypeArgc(methodRef, args, marks);
        var binding = methodRef.getBinding(selfType, args);
        var typeParameters = methodRef.getMethod().getTypeParameters();
        for (int i = 0; i < args.size(); i++) {
            var typeParameter = typeParameters.get(i);
            var arg = args.get(i);
            checkTypeArg(arg, marks);
            for (var subtrait : typeParameter.getTraits().map(t -> t.apply(binding, marks))) {
                if (!implementsTrait(arg, subtrait)) {
                    throw CJError.of(arg + " does not implement required trait " + subtrait, marks);
                }
            }
        }
        return new CJIRReifiedMethodRef(methodRef, args, binding);
    }

    private void checkMethodTypeArgc(CJIRMethodRef methodRef, List<CJIRType> args, CJMark... marks) {
        var expected = methodRef.getMethod().getTypeParameters().size();
        var actual = args.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " type args but got " + actual, marks);
        }
    }

    boolean implementsTrait(CJIRType type, CJIRTrait trait) {
        for (var subtrait : type.getTraits()) {
            if (extendsTrait(subtrait, trait)) {
                return true;
            }
        }
        return false;
    }

    boolean extendsTrait(CJIRTrait target, CJIRTrait trait) {
        if (target.equals(trait)) {
            return true;
        }
        for (var subtrait : target.getTraits()) {
            if (extendsTrait(subtrait, trait)) {
                return true;
            }
        }
        return false;
    }

    void checkType(CJIRType type, CJMark... marks) {
        if (type instanceof CJIRClassType) {
            var classType = (CJIRClassType) type;
            var item = classType.getItem();
            var args = classType.getArgs();
            checkItemArgs(item, args, marks);
            for (var arg : args) {
                checkType(arg, marks);
            }
        }
    }

    void checkTrait(CJIRTrait trait, CJMark... marks) {
        checkItemArgs(trait.getItem(), trait.getArgs(), marks);
        for (var arg : trait.getArgs()) {
            checkType(arg, marks);
        }
    }

    CJIRItem getListItem() {
        return getGlobal().getListItem();
    }

    CJIRItem getPromiseItem() {
        return getGlobal().getPromiseItem();
    }

    CJIRClassType itemToType(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        return getGlobal().itemToType(item, args, marks);
    }

    CJIRClassType getTypeWithArgs(String itemName, List<CJIRType> args, CJMark... marks) {
        return getGlobal().getTypeWithArgs(itemName, args, marks);
    }

    CJIRTrait itemToTrait(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        return getGlobal().itemToTrait(item, args, marks);
    }

    CJIRTrait getTraitWithArgs(String itemName, List<CJIRType> args, CJMark... marks) {
        return getGlobal().getTraitWithArgs(itemName, args, marks);
    }

    CJIRType getUnitType() {
        return getGlobal().getUnitType();
    }

    CJIRType getNoReturnType() {
        return getGlobal().getNoReturnType();
    }

    CJIRType getBoolType() {
        return getGlobal().getBoolType();
    }

    CJIRType getCharType() {
        return getGlobal().getCharType();
    }

    CJIRType getIntType() {
        return getGlobal().getIntType();
    }

    CJIRType getDoubleType() {
        return getGlobal().getDoubleType();
    }

    CJIRType getStringType() {
        return getGlobal().getStringType();
    }

    CJIRType getListType(CJIRType innerType) {
        return getGlobal().getListType(innerType);
    }

    CJIRType getPromiseType(CJIRType innerType) {
        return getGlobal().getPromiseType(innerType);
    }

    CJIRTrait getToBoolTrait() {
        return getGlobal().getToBoolTrait();
    }
}
