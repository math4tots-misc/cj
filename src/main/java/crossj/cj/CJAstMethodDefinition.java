package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;

public final class CJAstMethodDefinition extends CJAstItemMemberDefinition {
    private final List<CJAstTypeCondition> conditions;
    private final List<CJAstTypeParameter> typeParameters;
    private final List<CJAstParameter> parameters;
    private final CJAstTypeExpression returnType;
    private final Optional<CJAstExpression> body;

    public CJAstMethodDefinition(CJMark mark, List<CJAstTypeCondition> conditions, List<CJIRModifier> modifiers,
            String name, List<CJAstTypeParameter> typeParameters, List<CJAstParameter> parameters,
            CJAstTypeExpression returnType, Optional<CJAstExpression> body) {
        super(mark, modifiers, name);
        this.conditions = conditions;
        this.typeParameters = typeParameters;
        this.parameters = parameters;
        this.returnType = returnType;
        this.body = body;
    }

    public List<CJAstTypeCondition> getConditions() {
        return conditions;
    }

    public List<CJAstTypeParameter> getTypeParameters() {
        return typeParameters;
    }

    public List<CJAstParameter> getParameters() {
        return parameters;
    }

    public CJAstTypeExpression getReturnType() {
        return returnType;
    }

    public Optional<CJAstExpression> getBody() {
        return body;
    }
}
