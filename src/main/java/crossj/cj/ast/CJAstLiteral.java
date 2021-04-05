package crossj.cj.ast;

import crossj.cj.CJIRLiteralKind;
import crossj.cj.CJMark;

public final class CJAstLiteral extends CJAstExpression {
    private final CJIRLiteralKind kind;
    private final String rawText;

    public CJAstLiteral(CJMark mark, CJIRLiteralKind kind, String rawText) {
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

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitLiteral(this, a);
    }
}
