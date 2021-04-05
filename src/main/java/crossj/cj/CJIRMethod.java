package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;
import crossj.base.annotations.Nullable;
import crossj.cj.ast.CJAstMethodDefinition;

public final class CJIRMethod extends CJIRItemMember<CJAstMethodDefinition> {
    private final List<CJIRTypeCondition> conditions;
    private final List<CJIRTypeParameter> typeParameters;
    private final List<CJIRParameter> parameters = List.of();
    private CJIRType returnType = null;
    private final boolean implPresent;
    private final CJIRAnnotationProcessor annotation;
    private final CJIRExtraMethodInfo extra;
    private final Map<String, CJIRTypeParameter> typeParameterMap = Map.of();
    private Optional<CJIRExpression> body = Optional.empty();

    CJIRMethod(CJAstMethodDefinition ast, List<CJIRTypeCondition> conditions, List<CJIRTypeParameter> typeParameters,
            boolean implPresent, CJIRAnnotationProcessor annotation, CJIRExtraMethodInfo extra) {
        super(ast);
        this.conditions = conditions;
        this.typeParameters = typeParameters;
        this.implPresent = implPresent;
        this.annotation = annotation;
        this.extra = extra;

        for (var typeParameter : typeParameters) {
            typeParameterMap.put(typeParameter.getName(), typeParameter);
        }
    }

    public boolean isTest() {
        return annotation.isTest();
    }

    public boolean isSlowTest() {
        return annotation.isSlowTest();
    }

    public boolean isGeneric() {
        return annotation.isGeneric();
    }

    public boolean isGenericSelf() {
        return annotation.isGenericSelf() || isGeneric();
    }

    public boolean isVariadic() {
        return annotation.isVariadic();
    }

    @Nullable
    public CJIRExtraMethodInfo getExtra() {
        return extra;
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
