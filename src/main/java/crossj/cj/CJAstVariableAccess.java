package crossj.cj;

public final class CJAstVariableAccess extends CJAstExpression {
    private final String name;

    CJAstVariableAccess(CJMark mark, String name) {
        super(mark);
        this.name = name;
    }

    public String getName() {
        return name;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitVariableAccess(this, a);
    }
}
