package com.github.math4tots.java2cj;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;

import org.eclipse.jdt.core.dom.IMethodBinding;
import org.eclipse.jdt.core.dom.ITypeBinding;
import org.eclipse.jdt.core.dom.MethodDeclaration;
import org.eclipse.jdt.core.dom.SingleVariableDeclaration;

public final class Codegen {
    private final FSB prefix = new FSB();
    private final FSB out = new FSB();
    private ITypeBinding type;
    private HashMap<String, String> importMap = new HashMap<>();
    private HashSet<String> usedShortNames = new HashSet<>();

    public void emit(CUnit cu) {
        type = cu.ast.resolveBinding();
        prefix.line("package " + type.getPackage().getName() + ";");
        out.line("");
        out.line("class " + type.getName() + " {");
        out.indent();
        for (var method : cu.ast.getMethods()) {
            emitMethod(method);
        }
        out.dedent();
        out.line("}");
    }

    private String trType(ITypeBinding type) {
        var name = type.getQualifiedName();
        switch (name) {
            case "boolean": return "Bool";
            case "int": return "Int";
            case "java.lang.String": return "String";
            default: {
                var trName = importMap.get(name);
                if (trName != null) {
                    return trName;
                }
                var shortName = type.getName();
                assert !usedShortNames.contains(shortName);
                usedShortNames.add(shortName);
                importMap.put(name, shortName);
                prefix.line("import " + name);
                return shortName;
            }
        }
    }

    private void emitMethod(MethodDeclaration method) {
        var name = method.getName();
        var params = UT.cast(SingleVariableDeclaration.class, method.parameters());
        var trParams = UT.map(
            params,
            p -> {
                var rp = p.resolveBinding();
                return p.getName() + ": " +
                    trType(rp.getType());
            });
        out.line("def " + name + "(" + UT.join(", ", trParams) + ")");
        var body = method.getBody();
        if (body != null) {
        }
    }

    @Override
    public String toString() {
        return prefix.toString() + out.toString();
    }
}
