package crossj.cj.ir;

import crossj.base.List;
import crossj.cj.ast.CJAstItemMemberDefinition;

public abstract class CJIRItemMember<N extends CJAstItemMemberDefinition> extends CJIRNode<N> {
    protected CJIRItemMember(N ast) {
        super(ast);
    }

    public final List<CJIRModifier> getModifiers() {
        return ast.getModifiers();
    }

    public final String getName() {
        return ast.getName();
    }

    public final boolean isStatic() {
        return ast.isStatic();
    }

    public final boolean isPrivate() {
        return ast.isPrivate();
    }
}
