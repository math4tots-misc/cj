package crossj.cj;

import crossj.base.Optional;

public final class CJAstImport extends CJAstNode {
    private final String fullName;
    private final Optional<String> alias;

    CJAstImport(CJMark mark, String fullName, Optional<String> alias) {
        super(mark);
        this.fullName = fullName;
        this.alias = alias;
    }

    public String getFullName() {
        return fullName;
    }

    public String getAlias() {
        return alias.getOrElseDo(() -> fullName.substring(fullName.lastIndexOf('.') + 1));
    }
}
