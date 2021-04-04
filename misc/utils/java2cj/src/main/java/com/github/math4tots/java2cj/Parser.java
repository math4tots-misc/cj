package com.github.math4tots.java2cj;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.jdt.core.JavaCore;
import org.eclipse.jdt.core.dom.AST;
import org.eclipse.jdt.core.dom.ASTParser;
import org.eclipse.jdt.core.dom.CompilationUnit;
import org.eclipse.jdt.core.dom.FileASTRequestor;
import org.eclipse.jdt.core.dom.TypeDeclaration;

public final class Parser {
    private final ASTParser parser = ASTParser.newParser(AST.JLS14);
    private final List<String> sourceRoots = new ArrayList<>();

    public List<CUnit> parseFiles(List<String> paths) {
        parser.setResolveBindings(true);
        parser.setKind(ASTParser.K_COMPILATION_UNIT);
        var options = JavaCore.getOptions();
        options.put("org.eclipse.jdt.core.compiler.source", "10");
        parser.setCompilerOptions(options);
        String[] classpath = {};
        String[] sourceRoots = new String[this.sourceRoots.size()];
        for (int i = 0; i < sourceRoots.length; i++) {
            sourceRoots[i] = this.sourceRoots.get(i);
        }
        parser.setEnvironment(classpath, sourceRoots, getEncodings(sourceRoots.length), false);
        parser.setUnitName(paths.get(0));
        parser.setSource(readFile(paths.get(0)).toCharArray());
        List<CUnit> cus = new ArrayList<>();
        parser.createASTs(toStringArray(paths), getEncodings(paths.size()), new String[0], new FileASTRequestor() {
            @Override
            public void acceptAST(String sourceFilePath, CompilationUnit ast) {
                for (var element : ast.types()) {
                    if (element instanceof TypeDeclaration) {
                        cus.add(new CUnit(sourceFilePath, (TypeDeclaration) element));
                    }
                }
            }
        }, new NullProgressMonitor());
        return cus;
    }

    public void addSourceRoot(String sourceRoot) {
        sourceRoots.add(sourceRoot);
    }

    private static String[] toStringArray(List<String> strings) {
        var ret = new String[strings.size()];
        for (int i = 0; i < strings.size(); i++) {
            ret[i] = strings.get(i);
        }
        return ret;
    }

    private static String[] getEncodings(int n) {
        String[] encodings = new String[n];
        for (int i = 0; i < n; i++) {
            encodings[i] = "UTF-8";
        }
        return encodings;
    }

    private static String readFile(String path) {
        try {
            byte[] encoded = Files.readAllBytes(Paths.get(path));
            return new String(encoded, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
