package crossj.cj;

import crossj.base.List;
import crossj.base.Map;

public final class CJIRMethod extends CJIRItemMember<CJAstItemMemberDefinition> {
    private final List<CJIRTypeParameter> typeParameters = List.of();
    private final Map<String, CJIRTypeParameter> typeParameterMap = Map.of();

    CJIRMethod(CJAstItemMemberDefinition ast) {
        super(ast);
    }

    public List<CJIRTypeParameter> getTypeParameters() {
        return typeParameters;
    }

    public Map<String, CJIRTypeParameter> getTypeParameterMap() {
        return typeParameterMap;
    }
}
