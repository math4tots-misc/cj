package com.github.math4tots.java2cj;

import org.eclipse.jdt.core.dom.ITypeBinding;

public final class Codegen {
    private final FSB body = new FSB();
    private ITypeBinding type;

    public void emit(CUnit cu) {
        type = cu.ast.resolveBinding();
        body.line("package " + type.getPackage().getName() + ";");
        body.line("");
        body.line("class " + type.getName() + " {");
        body.line("}");
    }

    @Override
    public String toString() {
        return body.toString();
    }
}
