package crossj.cj;

import crossj.base.List;

public final class CJIRTypeParameter extends CJIRNode<CJAstTypeParameter> {
    private final List<CJIRTrait> traits = List.of();

    public CJIRTypeParameter(CJAstTypeParameter ast) {
        super(ast);
    }

    public String getName() {
        return ast.getName();
    }

    public List<CJIRTrait> getTraits() {
        return traits;
    }

    public boolean isItemLevel() {
        return ast.isItemLevel();
    }

    public boolean isMethodLevel() {
        return ast.isMethodLevel();
    }
}
