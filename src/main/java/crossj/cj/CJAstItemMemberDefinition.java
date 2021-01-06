package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;

public abstract class CJAstItemMemberDefinition extends CJAstNode {
    private final Optional<String> comment;
    private final List<CJAstAnnotationExpression> annotations;
    private final List<CJIRModifier> modifiers;
    private final String name;

    CJAstItemMemberDefinition(CJMark mark, Optional<String> comment, List<CJAstAnnotationExpression> annotations, List<CJIRModifier> modifiers,
            String name) {
        super(mark);
        this.comment = comment;
        this.annotations = annotations;
        this.modifiers = modifiers;
        this.name = name;
    }

    public Optional<String> getComment() {
        return comment;
    }

    public List<CJAstAnnotationExpression> getAnnotations() {
        return annotations;
    }

    public List<CJIRModifier> getModifiers() {
        return modifiers;
    }

    public String getName() {
        return name;
    }

    public boolean isStatic() {
        return modifiers.contains(CJIRModifier.Static);
    }
}
