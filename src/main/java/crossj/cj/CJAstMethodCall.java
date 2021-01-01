package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;

public final class CJAstMethodCall extends CJAstExpression {
    private final Optional<CJAstTypeExpression> owner;
    private final String name;
    private final List<CJAstExpression> args;

    CJAstMethodCall(CJMark mark, Optional<CJAstTypeExpression> owner, String name, List<CJAstExpression> args) {
        super(mark);
        this.owner = owner;
        this.name = name;
        this.args = args;
    }

    public Optional<CJAstTypeExpression> getOwner() {
        return owner;
    }

    public String getName() {
        return name;
    }

    public List<CJAstExpression> getArgs() {
        return args;
    }

    @Override
    public <R, A> R accept(CJAstExpressionVisitor<R, A> visitor, A a) {
        return visitor.visitMethodCall(this, a);
    }
}
