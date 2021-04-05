package crossj.cj.ast;

import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJMark;
import crossj.cj.ir.CJIRModifier;

public final class CJAstMethodDefinition extends CJAstItemMemberDefinition {
    private final List<CJAstTypeCondition> conditions;
    private final List<CJAstTypeParameter> typeParameters;
    private final List<CJAstParameter> parameters;
    private final Optional<CJAstTypeExpression> returnType;
    private final Optional<CJAstExpression> body;

    public CJAstMethodDefinition(CJMark mark, Optional<String> comment, List<CJAstAnnotationExpression> annotations,
            List<CJAstTypeCondition> conditions, List<CJIRModifier> modifiers, String name,
            List<CJAstTypeParameter> typeParameters, List<CJAstParameter> parameters,
            Optional<CJAstTypeExpression> returnType, Optional<CJAstExpression> body) {
        super(mark, comment, annotations, modifiers, name);
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

    public Optional<CJAstTypeExpression> getReturnType() {
        return returnType;
    }

    public Optional<CJAstExpression> getBody() {
        return body;
    }

    public boolean isAsync() {
        return getModifiers().contains(CJIRModifier.Async);
    }
}
