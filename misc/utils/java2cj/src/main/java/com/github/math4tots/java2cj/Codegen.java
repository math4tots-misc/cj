package com.github.math4tots.java2cj;

import org.eclipse.jdt.core.dom.IMethodBinding;
import org.eclipse.jdt.core.dom.ITypeBinding;

public final class Codegen {
    private final FSB out = new FSB();
    private ITypeBinding type;

    public void emit(CUnit cu) {
        type = cu.ast.resolveBinding();
        out.line("package " + type.getPackage().getName() + ";");
        out.line("");
        out.line("class " + type.getName() + " {");
        out.indent();
        for (var method : type.getDeclaredMethods()) {
            emitMethod(method);
        }
        out.dedent();
        out.line("}");
    }

    private void emitMethod(IMethodBinding method) {
        var name = method.getName();
        out.line("def " + name + "()");
    }

    @Override
    public String toString() {
        return out.toString();
    }
}
