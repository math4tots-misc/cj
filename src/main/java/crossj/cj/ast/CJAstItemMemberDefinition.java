package crossj.cj.ast;

import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJIRModifier;
import crossj.cj.CJMark;

public abstract class CJAstItemMemberDefinition extends CJAstNode {
    private final Optional<String> comment;
    private final List<CJAstAnnotationExpression> annotations;
    private final List<CJIRModifier> modifiers;
    private final String name;

    public CJAstItemMemberDefinition(CJMark mark, Optional<String> comment, List<CJAstAnnotationExpression> annotations, List<CJIRModifier> modifiers,
            String name) {
        super(mark);
        this.comment = comment;
        this.annotations = annotations;
        this.modifiers = modifiers;
        this.name = name;
    }

    public final Optional<String> getComment() {
        return comment;
    }

    public final List<CJAstAnnotationExpression> getAnnotations() {
        return annotations;
    }

    public final List<CJIRModifier> getModifiers() {
        return modifiers;
    }

    public final String getName() {
        return name;
    }

    public final boolean isStatic() {
        return modifiers.contains(CJIRModifier.Static);
    }

    public final boolean isPrivate() {
        return modifiers.contains(CJIRModifier.Private);
    }
}
