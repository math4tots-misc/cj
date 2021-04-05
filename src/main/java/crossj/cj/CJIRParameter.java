package crossj.cj;

import crossj.cj.ast.CJAstParameter;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRParameter extends CJIRNode<CJAstParameter> implements CJIRLocalVariableDeclaration {
    private final CJIRType type;

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
}
