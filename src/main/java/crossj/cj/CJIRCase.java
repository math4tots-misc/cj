package crossj.cj;

import crossj.base.List;

public final class CJIRCase extends CJIRItemMember<CJAstCaseDefinition> {
    private final int tag;
    private final List<CJIRType> types;

    CJIRCase(CJAstCaseDefinition ast, int tag, List<CJIRType> types) {
        super(ast);
        this.tag = tag;
        this.types = types;
    }

    public int getTag() {
        return tag;
    }

    public List<CJIRType> getTypes() {
        return types;
    }
}
