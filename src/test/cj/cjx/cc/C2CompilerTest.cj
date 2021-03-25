package cjx.cc

import cjx.cc.C2Compiler

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

    def assertFns(fns: String, code: Int) {
        Assert.equal(compiler.run("<string>", fns), code)
    }

    @test
    def sample0A() {
        assertExpr("5", 5)
    }

    @test
    def sample0() {
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

    @test
    def loops() {
        assertStmt("{ int i=0, j=0; for (i=0; i<=10; i=i+1) j=i+j; return j; }", 55)
        assertStmt("{ for (;;) {return 3;} return 5; }", 3)
        assertStmt("{ int i=0; while(i<10) { i=i+1; } return i; }", 10)
    }

    @test
    def addr() {
        assertStmt("{ int x=3; return *&x; }", 3)
        assertStmt("{ int x=3; int *y=&x; int **z=&y; return **z; }", 3)
        assertStmt("{ int x=3; int y=5; return *(&x+1); }", 5)
        assertStmt("{ int x=3; int y=5; return *(&y-1); }", 3)
        assertStmt("{ int x=3; int y=5; return *(&x-(-1)); }", 5)
        assertStmt("{ int x=3; int *y=&x; *y=5; return x; }", 5)
        assertStmt("{ int x=3; int y=5; *(&x+1)=7; return y; }", 7)
        assertStmt("{ int x=3; int y=5; *(&y-1)=7; return x; }", 7)
        assertStmt("{ int x=3; return (&x+2)-&x+3; }", 5)
    }

    @test
    def func() {
        assertFns("int foo() { return 5; } int main() { return foo(); }", 5)
        assertFns("int add(int a, int b) { return a + b; } int main() { return add(3, 17); }", 20)
    }

    @test
    def array() {
        assertStmt("int x[2]; int *y=x; *y=3; return *x;", 3)
        assertStmt("int x[2]; int *y=&x; *y=3; return *x;", 3)
        assertStmt("int x[3]; *x=3; *(x+1)=4; *(x+2)=5; return *x;", 3)
        assertStmt("int x[3]; *x=3; *(x+1)=4; *(x+2)=5; return *(x+1);", 4)
        assertStmt("int x[3]; *x=3; *(x+1)=4; *(x+2)=5; return *(x+2);", 5)

        assertStmt("int x[2][3]; int *y=x; *y=0; return **x;", 0)
        assertStmt("int x[2][3]; int *y=x; *(y+1)=1; return *(*x+1);", 1)
        assertStmt("int x[2][3]; int *y=x; *(y+2)=2; return *(*x+2);", 2)
        assertStmt("int x[2][3]; int *y=x; *(y+3)=3; return **(x+1);", 3)
        assertStmt("int x[2][3]; int *y=x; *(y+4)=4; return *(*(x+1)+1);", 4)
        assertStmt("int x[2][3]; int *y=x; *(y+5)=5; return *(*(x+1)+2);", 5)
    }

    @test
    def subscr() {
        assertStmt("int x[3]; *x=3; x[1]=4; x[2]=5; return *x;", 3)
        assertStmt("int x[3]; *x=3; x[1]=4; x[2]=5; return *(x+1);", 4)
        assertStmt("int x[3]; *x=3; x[1]=4; x[2]=5; return *(x+2);", 5)
        assertStmt("int x[3]; *x=3; x[1]=4; x[2]=5; return *(x+2);", 5)
        assertStmt("int x[3]; *x=3; x[1]=4; 2[x]=5; return *(x+2);", 5)

        assertStmt("int x[2][3]; int *y=x; y[0]=0; return x[0][0];", 0)
        assertStmt("int x[2][3]; int *y=x; y[1]=1; return x[0][1];", 1)
        assertStmt("int x[2][3]; int *y=x; y[2]=2; return x[0][2];", 2)
        assertStmt("int x[2][3]; int *y=x; y[3]=3; return x[1][0];", 3)
        assertStmt("int x[2][3]; int *y=x; y[4]=4; return x[1][1];", 4)
        assertStmt("int x[2][3]; int *y=x; y[5]=5; return x[1][2];", 5)
    }
}
