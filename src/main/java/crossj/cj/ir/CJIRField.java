package crossj.cj.ir;

import crossj.base.Optional;
import crossj.cj.CJAnnotationProcessor;
import crossj.cj.ast.CJAstFieldDefinition;
import crossj.cj.ir.meta.CJIRType;

public class CJIRField extends CJIRItemMember<CJAstFieldDefinition> {
    private final CJAnnotationProcessor annotations;
    private final int index;
    private final CJIRType type;
    private Optional<CJIRExpression> expression = Optional.empty();

    public CJIRField(CJAstFieldDefinition ast, CJAnnotationProcessor annotations, int index, CJIRType type) {
        super(ast);
        this.annotations = annotations;
        this.index = index;
        this.type = type;
    }

    public boolean isMutable() {
        return ast.isMutable();
    }

    public boolean isLateinit() {
        return annotations.isLateinit();
    }

    public boolean includeInMalloc() {
        return !isLateinit() && ast.getExpression().isEmpty();
    }

    public int getIndex() {
        return index;
    }

    public CJIRType getType() {
        return type;
    }

    public Optional<CJIRExpression> getExpression() {
        return expression;
    }

    public void setExpression(CJIRExpression expression) {
        this.expression = Optional.of(expression);
    }

    public String getGetterName() {
        return ast.getGetterName();
    }

    public String getSetterName() {
        return ast.getSetterName();
    }
}
