package crossj.cj;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;

public final class CJIRLocalContext extends CJIRContextBase {
    private final CJIRContext global;
    private final CJIRItem item;
    private final Optional<CJIRMethod> method;
    private final Map<String, CJIRVariableType> typeVariableCache = Map.of();

    CJIRLocalContext(CJIRContext global, CJIRItem item, Optional<CJIRMethod> method) {
        this.global = global;
        this.item = item;
        this.method = method;
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
            throw CJError.of("Trait " + shortName + " not found", marks);
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
            throw CJError.of("Type " + shortName + " not found", marks);
        }
        var item = global.loadItem(fullName, marks);
        if (!item.getKind().isTypeKind()) {
            throw CJError.of(fullName + " is not a type item (i.e. class or union)", marks);
        }
        return item;
    }

    CJIRClassType evalClassTypeExpression(CJAstTypeExpression typeExpression) {
        var item = getTypeItem(typeExpression.getName(), typeExpression.getMark());
        var args = typeExpression.getArgs().map(te -> evalTypeExpression(te));
        checkItemArgs(item, args, typeExpression.getMark());
        return new CJIRClassType(item, args);
    }

    CJIRType evalTypeExpression(CJAstTypeExpression typeExpression) {
        var typeVariable = getTypeVariableOrNull(typeExpression.getName(), typeExpression.getMark());
        if (typeVariable != null) {
            return typeVariable;
        }
        return evalClassTypeExpression(typeExpression);
    }

    CJIRTrait evalTraitExpression(CJAstTraitExpression traitExpression) {
        var traitItem = getTraitItem(traitExpression.getName(), traitExpression.getMark());
        var args = traitExpression.getArgs().map(te -> evalTypeExpression(te));
        checkItemArgs(traitItem, args, traitExpression.getMark());
        return new CJIRTrait(traitItem, args);
    }

    CJIRVariableType getTypeVariable(String shortName, CJMark... marks) {
        var type = getTypeVariableOrNull(shortName, marks);
        if (type == null) {
            throw CJError.of(shortName + " is not a type variable ", marks);
        }
        return type;
    }

    CJIRVariableType getTypeVariableOrNull(String shortName, CJMark... marks) {
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
