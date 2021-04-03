package com.github.math4tots.java2cj;

import org.eclipse.jdt.core.dom.CompilationUnit;

/**
 * Compilation Unit.
 */
public final class CUnit {
    public final String path;
    public final CompilationUnit ast;
    public CUnit(String path, CompilationUnit ast) {
        this.path = path;
        this.ast = ast;
    }
}
