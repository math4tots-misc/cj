package crossj.cj;

import crossj.base.Optional;

public class CJIRField extends CJIRItemMember<CJAstFieldDefinition> {
    private final int index;
    private final CJIRType type;
    private Optional<CJIRExpression> expression = Optional.empty();

    CJIRField(CJAstFieldDefinition ast, int index, CJIRType type) {
        super(ast);
        this.index = index;
        this.type = type;
    }

    public String getName() {
        return ast.getName();
    }

    public boolean isMutable() {
        return ast.isMutable();
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

    void setExpression(CJIRExpression expression) {
        this.expression = Optional.of(expression);
    }

    public String getGetterName() {
        return ast.getGetterName();
    }

    public String getSetterName() {
        return ast.getSetterName();
    }
}
