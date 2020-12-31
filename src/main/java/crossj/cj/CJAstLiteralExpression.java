package crossj.cj;

public final class CJAstLiteralExpression extends CJAstExpression {
    private final CJIRLiteralKind kind;
    private final String rawText;

    CJAstLiteralExpression(CJMark mark, CJIRLiteralKind kind, String rawText) {
        super(mark);
        this.kind = kind;
        this.rawText = rawText;
    }

    public CJIRLiteralKind getKind() {
        return kind;
    }

    public String getRawText() {
        return rawText;
    }
}
