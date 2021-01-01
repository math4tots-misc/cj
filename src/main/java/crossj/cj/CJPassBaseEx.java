package crossj.cj;

import crossj.base.List;

/**
 * Extends CJPassBase with some extra ops that are only available once pass02
 * has finished.
 */
public abstract class CJPassBaseEx extends CJPassBase {
    CJPassBaseEx(CJIRContext ctx) {
        super(ctx);
    }

    CJIRType evalTypeExpression(CJAstTypeExpression typeExpression) {
        var typeParameter = lctx.getItem().getTypeParameterMap().getOrNull(typeExpression.getName());
        if (typeParameter == null && lctx.getMethod().isPresent()) {
            typeParameter = lctx.getMethod().get().getTypeParameterMap().getOrNull(typeExpression.getName());
        }
        if (typeParameter != null) {
            if (typeExpression.getArgs().size() != 0) {
                throw CJError.of("type variables cannot accept arguments", typeExpression.getMark());
            }
            return new CJIRVariableType(typeParameter);
        }
        var typeItem = lctx.getTypeItem(typeExpression.getName(), typeExpression.getMark());
        var args = typeExpression.getArgs().map(te -> evalTypeExpression(te));
        checkItemArgs(typeExpression.getMark(), typeItem, args);
        return new CJIRClassType(typeItem, args);
    }

    CJIRTrait evalTraitExpression(CJAstTraitExpression traitExpression) {
        var traitItem = lctx.getTraitItem(traitExpression.getName(), traitExpression.getMark());
        var args = traitExpression.getArgs().map(te -> evalTypeExpression(te));
        checkItemArgs(traitExpression.getMark(), traitItem, args);
        return new CJIRTrait(traitItem, args);
    }

    void checkType(CJMark mark, CJIRType type) {
        if (type instanceof CJIRClassType) {
            var classType = (CJIRClassType) type;
            var item = classType.getItem();
            var args = classType.getArgs();
            checkItemArgs(mark, item, args);
            for (var arg : args) {
                checkType(mark, arg);
            }
        }
    }

    void checkTrait(CJMark mark, CJIRTrait trait) {
        checkItemArgs(mark, trait.getItem(), trait.getArgs());
        for (var arg : trait.getArgs()) {
            checkType(mark, arg);
        }
    }

    /**
     * Checks that the given type arguments are valid for the given item.
     */
    void checkItemArgs(CJMark mark, CJIRItem item, List<CJIRType> args) {
        checkItemArgc(mark, item, args);
        var bindings = item.getBinding(args);
        var typeParameters = item.getTypeParameters();
        for (int i = 0; i < args.size(); i++) {
            var typeParameter = typeParameters.get(i);
            var arg = args.get(i);
            for (var subtrait : typeParameter.getTraits().map(t -> t.apply(bindings))) {
                if (!implementsTrait(arg, subtrait)) {
                    var argMark = arg.getMarkOrDefault(mark);
                    throw CJError.of(arg + " does not implement required trait " + subtrait, argMark);
                }
            }
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

    private void checkItemArgc(CJMark mark, CJIRItem item, List<CJIRType> args) {
        var expected = item.getTypeParameters().size();
        var actual = args.size();
        if (expected != actual) {
            throw CJError.of("Expected " + expected + " type args but got " + actual, mark, item.getMark());
        }
    }
}
