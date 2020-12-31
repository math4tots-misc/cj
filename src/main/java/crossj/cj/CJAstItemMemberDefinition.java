package crossj.cj;

import crossj.base.List;

public abstract class CJAstItemMemberDefinition extends CJAstNode {
    private final List<CJIRModifier> modifiers;
    private final String name;

    CJAstItemMemberDefinition(CJMark mark, List<CJIRModifier> modifiers, String name) {
        super(mark);
        this.modifiers = modifiers;
        this.name = name;
    }

    public List<CJIRModifier> getModifiers() {
        return modifiers;
    }

    public String getName() {
        return name;
    }
}
