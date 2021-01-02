package crossj.cj;

public final class CJIRLiteral extends CJIRExpression {
    private final String rawText;

    CJIRLiteral(CJAstExpression ast, CJIRType type, String rawText) {
        super(ast, type);
        this.rawText = rawText;
    }

    public String getRawText() {
        return rawText;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLiteral(this, a);
    }
}
