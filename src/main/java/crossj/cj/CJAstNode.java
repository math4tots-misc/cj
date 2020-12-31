package crossj.cj;

public abstract class CJAstNode {
    private CJMark mark;

    CJAstNode(CJMark mark) {
        this.mark = mark;
    }

    public final CJMark getMark() {
        return mark;
    }
}
