package crossj.cj.ir;

import crossj.base.List;
import crossj.cj.ast.CJAstCaseDefinition;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRCase extends CJIRItemMember<CJAstCaseDefinition> {
    private final int tag;
    private final List<CJIRType> types;

    public CJIRCase(CJAstCaseDefinition ast, int tag, List<CJIRType> types) {
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
