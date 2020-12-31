package crossj.cj;

public final class CJAstImport extends CJAstNode {
    private final String fullName;

    CJAstImport(CJMark mark, String fullName) {
        super(mark);
        this.fullName = fullName;
    }

    public String getFullName() {
        return fullName;
    }

    public String getAlias() {
        return fullName.substring(fullName.lastIndexOf('.'));
    }
}
