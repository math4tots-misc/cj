package crossj.cj.ir;

import crossj.base.Optional;
import crossj.cj.ast.CJAstParameter;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRParameter extends CJIRNode<CJAstParameter> implements CJIRLocalVariableDeclaration {
    private final CJIRType type;
    private Optional<CJIRExpression> defaultExpression = Optional.empty();

    public CJIRParameter(CJAstParameter ast, CJIRType type) {
        super(ast);
        this.type = type;
    }

    @Override
    public boolean isMutable() {
        return ast.isMutable();
    }

    @Override
    public String getName() {
        return ast.getName();
    }

    @Override
    public CJIRType getVariableType() {
        return type;
    }

    public boolean hasDefault() {
        return getAst().getDefaultExpression().isPresent();
    }

    public Optional<CJIRExpression> getDefaultExpression() {
        return defaultExpression;
    }

    public void setDefaultExpression(Optional<CJIRExpression> defaultExpression) {
        this.defaultExpression = defaultExpression;
    }
}
