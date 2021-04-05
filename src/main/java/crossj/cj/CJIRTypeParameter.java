package crossj.cj;

import crossj.base.List;
import crossj.cj.ast.CJAstTypeParameter;

public final class CJIRTypeParameter extends CJIRNode<CJAstTypeParameter> {
    private final CJAnnotationProcessor annotation;
    private final List<CJIRTrait> traits = List.of();

    CJIRTypeParameter(CJAstTypeParameter ast) {
        super(ast);
        this.annotation = CJAnnotationProcessor.processTypeParameter(ast);
    }

    public CJAnnotationProcessor getAnnotation() {
        return annotation;
    }

    public boolean isGeneric() {
        return annotation.isGeneric();
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
