package crossj.cj;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.Repr;

public final class CJIRLocalContext extends CJIRContextBase {
    private final CJIRContext global;
    private final CJIRItem item;
    private final Optional<CJIRMethod> method;
    private final Map<String, CJIRVariableType> typeVariableCache = Map.of();
    private final CJIRType selfType;

    CJIRLocalContext(CJIRContext global, CJIRItem item, Optional<CJIRMethod> method) {
        this.global = global;
        this.item = item;
        this.method = method;
        if (item.isTrait()) {
            selfType = new CJIRSelfType(
                    new CJIRTrait(item, item.getTypeParameters().map(tp -> getTypeVariable(tp.getName()))));
        } else {
            selfType = new CJIRClassType(item, item.getTypeParameters().map(tp -> getTypeVariable(tp.getName())));
        }
    }

    public CJIRContext getGlobal() {
        return global;
    }

    public CJIRItem getItem() {
        return item;
    }

    public Optional<CJIRMethod> getMethod() {
        return method;
    }

    CJIRItem getTraitItem(String shortName, CJMark... marks) {
        var fullName = item.getShortNameMap().getOrNull(shortName);
        if (fullName == null) {
            throw CJError.of("Trait " + Repr.of(shortName) + " not found", marks);
        }
        var item = global.loadItem(fullName, marks);
        if (!item.getKind().isTraitKind()) {
            throw CJError.of(fullName + " is not a trait item", marks);
        }
        return item;
    }

    CJIRItem getTypeItem(String shortName, CJMark... marks) {
        var fullName = item.getShortNameMap().getOrNull(shortName);
        if (fullName == null) {
            throw CJError.of("Type " + Repr.of(shortName) + " not found", marks);
        }
        var item = global.loadItem(fullName, marks);
        if (!item.getKind().isTypeKind()) {
            throw CJError.of(fullName + " is not a type item (i.e. class or union)", marks);
        }
        return item;
    }

    private CJIRClassType evalClassTypeExpression(CJAstTypeExpression typeExpression) {
        var name = typeExpression.getName();
        switch (name) {
            case "Fn":
                name += typeExpression.getArgs().size() - 1;
                break;
            case "Tuple":
                name += typeExpression.getArgs().size();
                break;
        }
        var item = getTypeItem(name, typeExpression.getMark());
        var args = typeExpression.getArgs().map(te -> evalTypeExpression(te));
        checkItemArgs(item, args, typeExpression.getMark());
        return new CJIRClassType(item, args);
    }

    CJIRType evalTypeExpression(CJAstTypeExpression typeExpression) {
        var typeVariable = getTypeVariableOrNull(typeExpression.getName(), typeExpression.getMark());
        if (typeVariable != null) {
            assertNoTypeArgs(typeExpression);
            return typeVariable;
        }
        if (typeExpression.getName().equals("Self")) {
            assertNoTypeArgs(typeExpression);
            return selfType;
        }
        return evalClassTypeExpression(typeExpression);
    }

    private void assertNoTypeArgs(CJAstTypeExpression typeExpression) {
        if (typeExpression.getArgs().size() > 0) {
            throw CJError.of("Self type and type variables may not have type arguments", typeExpression.getMark());
        }
    }

    CJIRTrait evalTraitExpression(CJAstTraitExpression traitExpression) {
        var traitItem = getTraitItem(traitExpression.getName(), traitExpression.getMark());
        var args = traitExpression.getArgs().map(te -> evalTypeExpression(te));
        checkItemArgs(traitItem, args, traitExpression.getMark());
        return new CJIRTrait(traitItem, args);
    }

    private CJIRVariableType getTypeVariable(String shortName, CJMark... marks) {
        var type = getTypeVariableOrNull(shortName, marks);
        if (type == null) {
            throw CJError.of(shortName + " is not a type variable ", marks);
        }
        return type;
    }

    private CJIRVariableType getTypeVariableOrNull(String shortName, CJMark... marks) {
        if (!typeVariableCache.containsKey(shortName)) {
            typeVariableCache.put(shortName, getTypeVariableWithoutCacheOrNull(shortName, marks));
        }
        return typeVariableCache.get(shortName);
    }

    private CJIRVariableType getTypeVariableWithoutCacheOrNull(String shortName, CJMark... marks) {
        if (method.isPresent()) {
            var meth = method.get();
            var typeParameter = meth.getTypeParameterMap().getOrNull(shortName);
            if (typeParameter != null) {
                return new CJIRVariableType(typeParameter, List.of());
            }
        }
        var typeParameter = item.getTypeParameterMap().getOrNull(shortName);
        if (typeParameter == null) {
            return null;
        }
        var additionalTraits = List.<CJIRTrait>of();
        if (method.isPresent()) {
            var meth = method.get();
            for (var condition : meth.getConditions()) {
                if (condition.getTypeParameter().getAst() == typeParameter.getAst()) {
                    additionalTraits.addAll(condition.getTraits());
                }
            }
        }
        return new CJIRVariableType(typeParameter, additionalTraits);
    }
}
