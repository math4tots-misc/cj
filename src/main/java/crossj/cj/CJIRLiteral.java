package crossj.cj;

public final class CJIRLiteral extends CJIRExpression {
    private final CJIRLiteralKind kind;
    private final String rawText;

    CJIRLiteral(CJAstExpression ast, CJIRType type, CJIRLiteralKind kind, String rawText) {
        super(ast, type);
        this.kind = kind;
        this.rawText = rawText;
    }

    public CJIRLiteralKind getKind() {
        return kind;
    }

    public String getRawText() {
        return rawText;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLiteral(this, a);
    }
}