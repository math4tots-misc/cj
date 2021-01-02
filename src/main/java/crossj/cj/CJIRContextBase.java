package crossj.cj;

import crossj.base.List;

public abstract class CJIRContextBase {

    abstract CJIRContext getGlobal();

    /**
     * Checks that the given type arguments are valid for the given item.
     */
    void checkItemArgs(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        checkItemArgc(item, args, marks);
        var bindings = item.getBinding(args);
        var typeParameters = item.getTypeParameters();
        for (int i = 0; i < args.size(); i++) {
            var typeParameter = typeParameters.get(i);
            var arg = args.get(i);
            for (var subtrait : typeParameter.getTraits().map(t -> t.apply(bindings))) {
                if (!implementsTrait(arg, subtrait)) {
                    throw CJError.of(arg + " does not implement required trait " + subtrait, marks);
                }
            }
        }
    }

    void checkItemArgc(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        var expected = item.getTypeParameters().size();
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

    CJIRType getListType(CJIRType innerType, CJMark... marks) {
        return getGlobal().getListType(innerType, marks);
    }

    CJIRClassType itemToType(CJIRItem item, List<CJIRType> args, CJMark... marks) {
        return getGlobal().itemToType(item, args, marks);
    }

    CJIRClassType getTypeWithArgs(String itemName, List<CJIRType> args, CJMark... marks) {
        return getGlobal().getTypeWithArgs(itemName, args, marks);
    }

    CJIRType getUnitType() {
        return getGlobal().getUnitType();
    }

    CJIRType getBoolType() {
        return getGlobal().getBoolType();
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

}
