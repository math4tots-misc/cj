package crossj.cj;

import crossj.base.List;

public final class CJAstTypeParameter extends CJAstNode {
    private final boolean itemLevel;
    private final String name;
    private final boolean nullableAllowed;
    private final List<CJAstTraitExpression> traits;

    CJAstTypeParameter(CJMark mark, boolean itemLevel, String name, boolean nullableAllowed,
            List<CJAstTraitExpression> traits) {
        super(mark);
        this.itemLevel = itemLevel;
        this.name = name;
        this.nullableAllowed = nullableAllowed;
        this.traits = traits;
    }

    public boolean isItemLevel() {
        return itemLevel;
    }

    public boolean isMethodLevel() {
        return !isItemLevel();
    }

    public boolean isNullableAllowed() {
        return nullableAllowed;
    }

    public String getName() {
        return name;
    }

    public List<CJAstTraitExpression> getTraits() {
        return traits;
    }
}
