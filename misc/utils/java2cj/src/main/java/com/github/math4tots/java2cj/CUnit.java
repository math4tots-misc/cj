package com.github.math4tots.java2cj;

import org.eclipse.jdt.core.dom.TypeDeclaration;

/**
 * Compilation Unit.
 */
public final class CUnit {
    public final String path;
    public final TypeDeclaration ast;
    public CUnit(String path, TypeDeclaration ast) {
        this.path = path;
        this.ast = ast;
    }
}
