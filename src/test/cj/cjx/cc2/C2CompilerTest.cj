package cjx.cc2

import cjx.cc2.C2Compiler

class C2CompilerTest {
    static val compiler: C2Compiler = {
        val c = C2Compiler()
        c.includePrelude = false
        c
    }

    def runIntExpr(expr: String): Int = compiler.run(
        "<string>", "int main(){return " + expr + ";}")

    def assertExpr(expr: String, code: Int) {
        Assert.equal(runIntExpr(expr), code)
    }

    def assertStmt(stmts: String, code: Int) {
        Assert.equal(compiler.run("<string>", "int main(){" + stmts + "}"), code)
    }

    @test
    def sample0() {
        assertExpr("5", 5)
        assertExpr("-3", -3)
        assertExpr("5+7", 12)
        assertExpr("5-7", -2)
        assertExpr("5+(5-7)", 3)
        assertExpr("5*(5-7)", -10)
        assertExpr("5+6*7", 47)
        assertExpr("5*(9-6)", 15)
        assertExpr("(3+5)/2", 4)
        assertExpr("-10+20", 10)
        assertExpr("- -10", 10)
        assertExpr("- - +10", 10)
    }

    @test
    def sample1() {
        assertExpr("0==1", 0)
        assertExpr("42==42", 1)
        assertExpr("0!=1", 1)
        assertExpr("42!=42", 0)

        assertExpr("0<1", 1)
        assertExpr("1<1", 0)
        assertExpr("2<1", 0)
        assertExpr("0<=1", 1)
        assertExpr("1<=1", 1)
        assertExpr("2<=1", 0)

        assertExpr("1>0", 1)
        assertExpr("1>1", 0)
        assertExpr("1>2", 0)
        assertExpr("1>=0", 1)
        assertExpr("1>=1", 1)
        assertExpr("1>=2", 0)
    }

    @test
    def sample2() {
        assertStmt("{int a=3; return a;}", 3)
        assertStmt("{int a=3; int z=5; return a+z;}", 8)
        assertStmt("{int a; int b; a=b=3; return a+b; } ", 6)

        assertStmt("{1; 2; return 3;}", 3)
        assertStmt("{ {1; {2;} return 3;} }", 3)
        assertStmt("{ ;;; return 5; }", 5)
    }

    @test
    def if_() {
        assertStmt("{ if (0) return 2; return 3; }", 3)
        assertStmt("{ if (1-1) return 2; return 3; }", 3)
        assertStmt("{ if (1) return 2; return 3; }", 2)
        assertStmt("{ if (2-1) return 2; return 3; }", 2)
        assertStmt("{ if (0) { 1; 2; return 3; } else { return 4; } }", 4)
        assertStmt("{ if (1) { 1; 2; return 3; } else { return 4; } }", 3)
    }
}
