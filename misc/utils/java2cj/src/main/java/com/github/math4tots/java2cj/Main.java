package com.github.math4tots.java2cj;

import java.util.Arrays;

public class Main {
    private static final Parser parser = new Parser();

    public static void main(String[] args) {
        var paths = Arrays.asList(args);
        var cus = parser.parseFiles(paths);
        System.out.println("COUNT = " + cus.size());
        for (var cu : cus) {
            var type = cu.ast.resolveBinding();
            System.out.println("######## " + type.getQualifiedName() + " ########");
            var cgen = new Codegen();
            cgen.emit(cu);
            System.out.println(cgen.toString());
        }
    }
}
