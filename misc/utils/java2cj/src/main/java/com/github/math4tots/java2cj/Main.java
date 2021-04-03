package com.github.math4tots.java2cj;

import java.util.Arrays;

public class Main {
    private static final Parser parser = new Parser();

    public static void main(String[] args) {
        var paths = Arrays.asList(args);
        var cus = parser.parseFiles(paths);
        for (var cu : cus) {
            System.out.println("##########################################");
            System.out.println(cu.path);
            System.out.println("##########################################");
            // System.out.println(cu.ast);
        }
    }
}
