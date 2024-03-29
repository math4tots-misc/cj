package crossj.cj.ir;

import crossj.cj.CJMark;
import crossj.cj.ast.CJAstNode;

public abstract class CJIRNode<N extends CJAstNode> {
    protected final N ast;

    protected CJIRNode(N ast) {
        this.ast = ast;
    }

    public final N getAst() {
        return ast;
    }

    public final CJMark getMark() {
        return ast.getMark();
    }
}
