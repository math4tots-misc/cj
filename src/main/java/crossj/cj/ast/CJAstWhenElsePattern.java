package crossj.cj.ast;

import crossj.base.List;
import crossj.base.Optional;
import crossj.base.Tuple3;
import crossj.cj.CJMark;

public final class CJAstWhenElsePattern {
    private final CJMark mark;
    private final Optional<String> caseNameVar;
    private final List<Tuple3<CJMark, Boolean, String>> decls;
    private final boolean variadic;

    public CJAstWhenElsePattern(CJMark mark, Optional<String> caseNameVar, List<Tuple3<CJMark, Boolean, String>> decls,
            boolean variadic) {
        this.mark = mark;
        this.caseNameVar = caseNameVar;
        this.decls = decls;
        this.variadic = variadic;
    }

    public CJMark getMark() {
        return mark;
    }

    public Optional<String> getCaseNameVar() {
        return caseNameVar;
    }

    public List<Tuple3<CJMark, Boolean, String>> getDecls() {
        return decls;
    }

    public boolean isVariadic() {
        return variadic;
    }
}
