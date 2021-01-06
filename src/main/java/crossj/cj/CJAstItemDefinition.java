package crossj.cj;

import crossj.base.List;
import crossj.base.Optional;

public final class CJAstItemDefinition extends CJAstNode {
    private final String packageName;
    private final List<CJAstImport> imports;
    private final Optional<String> comment;
    private final List<CJAstAnnotationExpression> annotations;
    private final List<CJIRModifier> modifiers;
    private final CJIRItemKind kind;
    private final String shortName;
    private final List<CJAstTypeParameter> typeParameters;
    private final List<CJAstTraitDeclaration> traitDeclarations;
    private final List<CJAstItemMemberDefinition> members;

    CJAstItemDefinition(
            CJMark mark,
            String packageName,
            List<CJAstImport> imports,
            Optional<String> comment,
            List<CJAstAnnotationExpression> annotations,
            List<CJIRModifier> modifiers,
            CJIRItemKind kind,
            String shortName,
            List<CJAstTypeParameter> typeParameters,
            List<CJAstTraitDeclaration> traitDeclarations,
            List<CJAstItemMemberDefinition> members) {
        super(mark);
        this.packageName = packageName;
        this.imports = imports;
        this.comment = comment;
        this.annotations = annotations;
        this.modifiers = modifiers;
        this.kind = kind;
        this.shortName = shortName;
        this.typeParameters = typeParameters;
        this.traitDeclarations = traitDeclarations;
        this.members = members;
    }

    public String getPackageName() {
        return packageName;
    }

    public List<CJAstImport> getImports() {
        return imports;
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

    public CJIRItemKind getKind() {
        return kind;
    }

    public String getShortName() {
        return shortName;
    }

    public List<CJAstTypeParameter> getTypeParameters() {
        return typeParameters;
    }

    public List<CJAstTraitDeclaration> getTraitDeclarations() {
        return traitDeclarations;
    }

    public List<CJAstItemMemberDefinition> getMembers() {
        return members;
    }
}
