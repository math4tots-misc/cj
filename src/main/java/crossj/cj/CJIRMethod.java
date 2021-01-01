package crossj.cj;

import crossj.base.List;
import crossj.base.Map;
import crossj.base.Optional;

public final class CJIRMethod extends CJIRItemMember<CJAstMethodDefinition> {
    private final List<CJIRTypeCondition> conditions;
    private final List<CJIRTypeParameter> typeParameters;
    private final List<CJIRParameter> parameters = List.of();
    private CJIRType returnType = null;
    private final Map<String, CJIRTypeParameter> typeParameterMap = Map.of();
    private Optional<CJIRExpression> body = Optional.empty();

    CJIRMethod(CJAstMethodDefinition ast, List<CJIRTypeCondition> conditions,  List<CJIRTypeParameter> typeParameters) {
        super(ast);
        this.conditions = conditions;
        this.typeParameters = typeParameters;

        for (var typeParameter : typeParameters) {
            typeParameterMap.put(typeParameter.getName(), typeParameter);
        }
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

    public Optional<CJIRExpression> getBody() {
        return body;
    }

    public void setBody(CJIRExpression body) {
        this.body = Optional.of(body);
    }

    public Map<String, CJIRTypeParameter> getTypeParameterMap() {
        return typeParameterMap;
    }

    void setReturnType(CJIRType returnType) {
        this.returnType = returnType;
    }
}
