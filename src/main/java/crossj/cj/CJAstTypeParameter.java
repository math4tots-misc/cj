package crossj.cj;

import crossj.base.List;

public final class CJAstTypeParameter extends CJAstNode {
    private final boolean itemLevel;
    private final String name;
    private final List<CJAstTraitExpression> traits;

    CJAstTypeParameter(CJMark mark, boolean itemLevel, String name, List<CJAstTraitExpression> traits) {
        super(mark);
        this.itemLevel = itemLevel;
        this.name = name;
        this.traits = traits;
    }

    public boolean isItemLevel() {
        return itemLevel;
    }

    public boolean isMethodLevel() {
        return !isItemLevel();
    }

    public String getName() {
        return name;
    }

    public List<CJAstTraitExpression> getTraits() {
        return traits;
    }
}
