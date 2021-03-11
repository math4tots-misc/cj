package crossj.cj;

public final class CJIRJSBlob extends CJIRExpression {
    private final String text;

    public CJIRJSBlob(CJAstExpression ast, CJIRType type, String text) {
        super(ast, type);
        this.text = text;
    }

    public String getText() {
        return text;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitJSBlob(this, a);
    }
}
