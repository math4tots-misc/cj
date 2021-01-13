package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;

public final class CJIRMethod extends CJIRItemMember<CJAstMethodDefinition> {
    private final List<CJIRTypeCondition> conditions;
    private final List<CJIRTypeParameter> typeParameters;
    private final List<CJIRParameter> parameters = List.of();
    private CJIRType returnType = null;
    private final boolean implPresent;
    private final boolean test;
    private final boolean generic;
    private final Map<String, CJIRTypeParameter> typeParameterMap = Map.of();
    private Optional<CJIRExpression> body = Optional.empty();

    CJIRMethod(CJAstMethodDefinition ast, List<CJIRTypeCondition> conditions, List<CJIRTypeParameter> typeParameters,
            boolean implPresent, boolean test, boolean generic) {
        super(ast);
        this.conditions = conditions;
        this.typeParameters = typeParameters;
        this.implPresent = implPresent;
        this.test = test;
        this.generic = generic;

        for (var typeParameter : typeParameters) {
            typeParameterMap.put(typeParameter.getName(), typeParameter);
        }
    }

    public boolean isTest() {
        return test;
    }

    public boolean isGeneric() {
        return generic;
    }

    public List<CJIRTypeCondition> getConditions() {
        return conditions;
    }

    public List<CJIRTypeParameter> getTypeParameters() {
        return typeParameters;
    }

    public List<CJIRParameter> getParameters() {
        return parameters;
    }

    public CJIRType getReturnType() {
        return returnType;
    }

    /**
     * Mostly the same as getReturnType, except if this is an async method,
     * should return the Promise's type argument.
     */
    public CJIRType getInnerReturnType() {
        if (isAsync()) {
            Assert.that(returnType.isPromiseType());
            return ((CJIRClassType) returnType).getArgs().get(0);
        } else {
            return returnType;
        }
    }

    public Optional<CJIRExpression> getBody() {
        return body;
    }

    public void setBody(CJIRExpression body) {
        this.body = Optional.of(body);
    }

    public boolean hasImpl() {
        return implPresent;
    }

    public boolean isAsync() {
        return getModifiers().contains(CJIRModifier.Async);
    }

    public Map<String, CJIRTypeParameter> getTypeParameterMap() {
        return typeParameterMap;
    }

    void setReturnType(CJIRType returnType) {
        this.returnType = returnType;
    }
}
