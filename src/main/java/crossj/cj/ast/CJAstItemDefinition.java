package crossj.cj.ast;

import crossj.base.List;
import crossj.base.Optional;
import crossj.cj.CJIRItemKind;
import crossj.cj.CJIRModifier;
import crossj.cj.CJMark;

public final class CJAstItemDefinition extends CJAstItemMemberDefinition {
    private final String packageName;
    private final List<List<CJAstImport>> importsCombo;
    private final CJIRItemKind kind;
    private final List<CJAstTypeParameter> typeParameters;
    private final List<CJAstTraitDeclaration> traitDeclarations;
    private final List<CJAstItemMemberDefinition> members;
    private final boolean simpleUnion;

    public CJAstItemDefinition(CJMark mark, String packageName, List<List<CJAstImport>> importsCombo, Optional<String> comment,
            List<CJAstAnnotationExpression> annotations, List<CJIRModifier> modifiers, CJIRItemKind kind,
            String shortName, List<CJAstTypeParameter> typeParameters, List<CJAstTraitDeclaration> traitDeclarations,
            List<CJAstItemMemberDefinition> members) {
        super(mark, comment, annotations, modifiers, shortName);
        this.packageName = packageName;
        this.importsCombo = importsCombo;
        this.kind = kind;
        this.typeParameters = typeParameters;
        this.traitDeclarations = traitDeclarations;
        this.members = members;
        this.simpleUnion = kind == CJIRItemKind.Union && members.filter(c -> c instanceof CJAstCaseDefinition)
                .map(c -> (CJAstCaseDefinition) c).all(c -> c.getTypes().isEmpty());
    }

    public String getPackageName() {
        return packageName;
    }

    public List<List<CJAstImport>> getImportsCombo() {
        return importsCombo;
    }

    public List<CJAstImport> getImports() {
        return importsCombo.flatMap(x -> x);
    }

    public CJIRItemKind getKind() {
        return kind;
    }

    public String getShortName() {
        return getName();
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

    /**
     * Indicates that this item is a union where all of its cases have no additional
     * data.
     *
     * This means that this union may be effectively treated like an enum.
     */
    public boolean isSimpleUnion() {
        return simpleUnion;
    }

    public boolean isValidCompanionClass() {
        return kind != CJIRItemKind.Trait && typeParameters.isEmpty();
    }
}
