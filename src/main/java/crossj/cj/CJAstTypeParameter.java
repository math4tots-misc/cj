package crossj.cj;

import crossj.base.List;

public final class CJAstTypeParameter extends CJAstNode {
    private final String name;
    private final List<CJAstTraitExpression> traits;

    CJAstTypeParameter(CJMark mark, String name, List<CJAstTraitExpression> traits) {
        super(mark);
        this.name = name;
        this.traits = traits;
    }

    public String getName() {
        return name;
    }

    public List<CJAstTraitExpression> getTraits() {
        return traits;
    }
}
