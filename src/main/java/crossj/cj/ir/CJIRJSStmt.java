package crossj.cj.ir;

import crossj.cj.ast.CJAstExpression;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRJSStmt extends CJIRExpression {
    private final String jsStmt;

    public CJIRJSStmt(CJAstExpression ast, CJIRType type, String jsStmt) {
        super(ast, type);
        this.jsStmt = jsStmt;
    }

    public String getJsStmt() {
        return jsStmt;
    }

    @Override
    public <R, A> R accept(CJIRExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitJSStmt(this, a);
    }
}
