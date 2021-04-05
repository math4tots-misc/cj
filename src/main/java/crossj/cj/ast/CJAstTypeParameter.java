package crossj.cj.ast;

import crossj.base.List;
import crossj.cj.CJMark;

public final class CJAstTypeParameter extends CJAstNode {
    private final boolean itemLevel;
    private final List<CJAstAnnotationExpression> annotations;
    private final String name;
    private final List<CJAstTraitExpression> traits;

    public CJAstTypeParameter(CJMark mark, boolean itemLevel, List<CJAstAnnotationExpression> annotations, String name,
            List<CJAstTraitExpression> traits) {
        super(mark);
        this.itemLevel = itemLevel;
        this.annotations = annotations;
        this.name = name;
        this.traits = traits;
    }

    public boolean isItemLevel() {
        return itemLevel;
    }

    public boolean isMethodLevel() {
        return !isItemLevel();
    }

    public List<CJAstAnnotationExpression> getAnnotations() {
        return annotations;
    }

    public String getName() {
        return name;
    }

    public List<CJAstTraitExpression> getTraits() {
        return traits;
    }
}
