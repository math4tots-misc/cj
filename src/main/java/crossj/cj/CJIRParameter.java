package crossj.cj;

public final class CJIRParameter extends CJIRNode<CJAstParameter> {
    private final CJIRType type;

    CJIRParameter(CJAstParameter ast, CJIRType type) {
        super(ast);
        this.type = type;
    }

    public String getName() {
        return ast.getName();
    }

    public CJIRType getType() {
        return type;
    }
}
