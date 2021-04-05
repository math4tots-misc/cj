package crossj.cj.ast;

import crossj.base.Optional;
import crossj.cj.CJMark;

public final class CJAstImport extends CJAstNode {
    private final String fullName;
    private final Optional<String> alias;

    public CJAstImport(CJMark mark, String fullName, Optional<String> alias) {
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
