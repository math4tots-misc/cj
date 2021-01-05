package crossj.cj;

import crossj.base.List;

public abstract class CJIRItemMember<N extends CJAstItemMemberDefinition> extends CJIRNode<N> {
    CJIRItemMember(N ast) {
        super(ast);
    }

    public List<CJIRModifier> getModifiers() {
        return ast.getModifiers();
    }

    public String getName() {
        return ast.getName();
    }

    public boolean isStatic() {
        return ast.isStatic();
    }
}
