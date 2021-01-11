package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;

public final class CJIRItem extends CJIRNode<CJAstItemDefinition> {
    private final boolean nullable;
    private final List<String> deriveList;
    private final String fullName;
    private final List<CJIRTypeParameter> typeParameters = List.of();
    private final List<CJIRTraitDeclaration> traitDeclarations = List.of();
    private final List<CJIRMethod> methods = List.of();
    private final List<CJIRField> fields = List.of();
    private final List<CJIRCase> cases;
    private final Map<String, String> shortNameMap;
    private final Map<String, CJIRTypeParameter> typeParameterMap = Map.of();
    private final Map<String, CJIRMethod> methodMap = Map.of();

    CJIRItem(CJAstItemDefinition ast, boolean nullable, List<String> deriveList) {
        super(ast);
        this.nullable = nullable;
        this.deriveList = deriveList;
        this.fullName = ast.getPackageName() + "." + ast.getShortName();
        this.cases = ast.getKind() == CJIRItemKind.Union ? List.of() : null;

        shortNameMap = Map.of();
        for (var autoImportName : CJIRContext.autoImportItemNames) {
            var shortName = autoImportName.substring(autoImportName.lastIndexOf('.') + 1);
            shortNameMap.put(shortName, autoImportName);
        }
        for (var imp : ast.getImports()) {
            shortNameMap.put(imp.getAlias(), imp.getFullName());
        }
        shortNameMap.put(ast.getShortName(), fullName);
    }

    public boolean isNullable() {
        return nullable;
    }

    public List<String> getDeriveList() {
        return deriveList;
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
}
