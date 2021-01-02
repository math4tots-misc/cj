package crossj.cj;

import crossj.base.Assert;
import crossj.base.List;
import crossj.base.Map;

public final class CJIRItem extends CJIRNode<CJAstItemDefinition> {
    private final String fullName;
    private final List<CJIRTypeParameter> typeParameters = List.of();
    private final List<CJIRTraitDeclaration> traitDeclarations = List.of();
    private final List<CJIRItemMember<?>> members = List.of();
    private final Map<String, String> shortNameMap;
    private final Map<String, CJIRTypeParameter> typeParameterMap = Map.of();
    private final Map<String, CJIRMethod> methodMap = Map.of();

    CJIRItem(CJAstItemDefinition ast) {
        super(ast);
        this.fullName = ast.getPackageName() + "." + ast.getShortName();

        shortNameMap = Map.of();
        for (var imp : ast.getImports()) {
            shortNameMap.put(imp.getAlias(), imp.getFullName());
        }
        shortNameMap.put(ast.getShortName(), fullName);
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

    public List<CJIRItemMember<?>> getMembers() {
        return members;
    }

    public Map<String, String> getShortNameMap() {
        return shortNameMap;
    }

    public Map<String, CJIRTypeParameter> getTypeParameterMap() {
        return typeParameterMap;
    }

    public CJIRBinding getBinding(List<CJIRType> args) {
        Assert.equals(typeParameters.size(), args.size());
        var binding = new CJIRBinding();
        for (int i = 0; i < args.size(); i++) {
            binding.put(typeParameters.get(i).getName(), args.get(i));
        }
        return binding;
    }

    /**
     * Gets the CJIRMethod directly declared in this item.
     * @param shortName
     * @return
     */
    public CJIRMethod getMethodOrNull(String shortName) {
        if (!methodMap.containsKey(shortName)) {
            for (var member : members) {
                if (member instanceof CJIRMethod && member.getName().equals(shortName)) {
                    methodMap.put(shortName, (CJIRMethod) member);
                    break;
                }
            }
        }
        return methodMap.get(shortName);
    }
}
