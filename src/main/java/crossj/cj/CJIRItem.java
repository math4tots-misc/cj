package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;
import crossj.base.Pair;
import crossj.cj.ast.CJAstItemDefinition;
import crossj.cj.ir.meta.CJIRClassType;
import crossj.cj.ir.meta.CJIRSelfType;
import crossj.cj.ir.meta.CJIRTrait;
import crossj.cj.ir.meta.CJIRTraitOrClassType;
import crossj.cj.ir.meta.CJIRType;

public final class CJIRItem extends CJIRNode<CJAstItemDefinition> {
    private final boolean deriveEq;
    private final boolean deriveHash;
    private final boolean deriveRepr;
    private final boolean derivePod;
    private final boolean deriveDefault;
    private final CJAnnotationProcessor annotations;
    private final String fullName;
    private final List<CJIRTypeParameter> typeParameters = List.of();
    private final List<CJIRTraitDeclaration> traitDeclarations = List.of();
    private final List<CJIRMethod> methods = List.of();
    private final List<CJIRField> fields = List.of();
    private final List<CJIRCase> cases;
    private final Map<String, String> shortNameMap;
    private final Map<String, CJIRTypeParameter> typeParameterMap = Map.of();
    private final Map<String, CJIRMethod> methodMap = Map.of();
    private final Map<CJIRItem, String> implicitsTypeItemMap = Map.of();
    private final List<Pair<CJIRItem, String>> implicitsTraitsList = List.of();

    CJIRItem(CJAstItemDefinition ast, CJAnnotationProcessor annotations) {
        super(ast);
        this.annotations = annotations;
        this.fullName = ast.getPackageName() + "." + ast.getShortName();
        this.cases = ast.getKind() == CJIRItemKind.Union ? List.of() : null;

        // process derive lists
        {
            boolean deriveEq = false;
            boolean deriveHash = false;
            boolean deriveRepr = false;
            boolean derivePod = false;
            boolean deriveDefault = false;
            for (var command : annotations.getDeriveList()) {
                switch (command) {
                    case "eq":
                        deriveEq = true;
                        break;
                    case "hash":
                        deriveEq = true;
                        deriveHash = true;
                        break;
                    case "repr":
                        deriveRepr = true;
                        break;
                    case "pod":
                        deriveEq = true;
                        deriveHash = true;
                        deriveRepr = true;
                        derivePod = true;
                        break;
                    case "default":
                        deriveDefault = true;
                        break;
                    default:
                        throw CJError.of("Unrecognized derive command: " + command, ast.getMark());
                }
            }
            this.deriveEq = deriveEq;
            this.deriveHash = deriveHash;
            this.deriveRepr = deriveRepr;
            this.derivePod = derivePod;
            this.deriveDefault = deriveDefault;
        }

        shortNameMap = Map.of();
        for (var autoImportName : CJContext.autoImportItemNames) {
            var shortName = autoImportName.substring(autoImportName.lastIndexOf('.') + 1);
            shortNameMap.put(shortName, autoImportName);
        }
        for (var imp : ast.getImports()) {
            shortNameMap.put(imp.getAlias(), imp.getFullName());
        }
        shortNameMap.put(ast.getShortName(), fullName);
    }

    public boolean isDeriveEq() {
        return deriveEq;
    }

    public boolean isDeriveHash() {
        return deriveHash;
    }

    public boolean isDeriveRepr() {
        return deriveRepr;
    }

    public boolean isDerivePod() {
        return derivePod;
    }

    public boolean isDeriveDefault() {
        return deriveDefault;
    }

    public boolean isNullable() {
        return annotations.isNullable();
    }

    public List<Pair<String, String>> getUnprocessedImplicits() {
        return annotations.getImplicits();
    }

    public List<Pair<CJIRItem, String>> getImplicitsTraitsList() {
        return implicitsTraitsList;
    }

    public Map<CJIRItem, String> getImplicitsTypeItemMap() {
        return implicitsTypeItemMap;
    }

    public boolean isSimpleUnion() {
        return ast.isSimpleUnion();
    }

    public List<CJIRModifier> getModifiers() {
        return ast.getModifiers();
    }

    public CJIRItemKind getKind() {
        return ast.getKind();
    }

    public boolean isTrait() {
        return getKind() == CJIRItemKind.Trait;
    }

    public boolean isNative() {
        return getModifiers().contains(CJIRModifier.Native);
    }

    public String getPackageName() {
        return ast.getPackageName();
    }

    public String getShortName() {
        return ast.getShortName();
    }

    public String getFullName() {
        return fullName;
    }

    public List<CJIRTypeParameter> getTypeParameters() {
        return typeParameters;
    }

    public List<CJIRTraitDeclaration> getTraitDeclarations() {
        return traitDeclarations;
    }

    public List<CJIRMethod> getMethods() {
        return methods;
    }

    public List<CJIRField> getFields() {
        return fields;
    }

    public CJIRField findFieldOrNull(String fieldName) {
        for (var field : fields) {
            if (field.getName().equals(fieldName)) {
                return field;
            }
        }
        return null;
    }

    public List<CJIRCase> getCases() {
        if (cases == null) {
            throw new NullPointerException();
        }
        return cases;
    }

    public Map<String, String> getShortNameMap() {
        return shortNameMap;
    }

    public Map<String, CJIRTypeParameter> getTypeParameterMap() {
        return typeParameterMap;
    }

    public CJIRBinding getBinding(List<CJIRType> args) {
        CJIRType selfType = isTrait() ? new CJIRSelfType(new CJIRTrait(this, args)) : new CJIRClassType(this, args);
        return getBindingWithSelfType(selfType, args);
    }

    public CJIRBinding getBindingWithSelfType(CJIRType selfType, List<CJIRType> args) {
        Assert.equals(typeParameters.size(), args.size());
        var map = Map.<String, CJIRType>of();
        for (int i = 0; i < args.size(); i++) {
            map.put(typeParameters.get(i).getName(), args.get(i));
        }
        return new CJIRBinding(selfType, map);
    }

    /**
     * Gets the CJIRMethod directly declared in this item.
     *
     * @param shortName
     * @return
     */
    public CJIRMethod getMethodOrNull(String shortName) {
        if (!methodMap.containsKey(shortName)) {
            for (var method : methods) {
                if (method.getName().equals(shortName)) {
                    methodMap.put(shortName, method);
                    break;
                }
            }
        }
        return methodMap.getOrNull(shortName);
    }

    public CJIRTraitOrClassType toTraitOrClassType() {
        List<CJIRType> args = typeParameters.map(tp -> new CJIRVariableType(tp, List.of()));
        return isTrait() ? new CJIRTrait(this, args) : new CJIRClassType(this, args);
    }

    /**
     * Like toTraitOrClassType, but the type variables implement all traits asked
     * for in all of this item's trait declarations.
     */
    CJIRTraitOrClassType toFullyImplementingTraitOrClassType() {
        List<CJIRVariableType> variables = typeParameters.map(tp -> new CJIRVariableType(tp, List.of()));
        List<CJIRType> args = variables.map(v -> v);
        var map = Map.fromIterable(variables.map(v -> Pair.of(v.getName(), v)));
        for (var decl : traitDeclarations) {
            for (var cond : decl.getConditions()) {
                var variable = map.get(cond.getTypeParameter().getName());
                var additionalTraits = variable.getAdditionalTraits();
                for (var trait : cond.getTraits()) {
                    if (!additionalTraits.contains(trait)) {
                        additionalTraits.add(trait);
                    }
                }
            }
        }
        return isTrait() ? new CJIRTrait(this, args) : new CJIRClassType(this, args);
    }

    public boolean isValidCompanionClass() {
        return getAst().isValidCompanionClass();
    }
}
