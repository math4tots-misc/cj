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
    def sample0B() {
        compiler.run("sample0.c", include_str!("sample0.c"))
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

    @test
    def sizeof() {
        assertStmt("int x; return sizeof(x);", 4)
        assertStmt("int x; return sizeof x;", 4)
        assertStmt("int *x; return sizeof(x);", 4)
        assertStmt("int x[4]; return sizeof(x);", 4 * 4)
        assertStmt("int x[3][4]; return sizeof(x);", 48)
        assertStmt("int x[3][4]; return sizeof(*x);", 16)
        assertStmt("int x[3][4]; return sizeof(**x);", 4)
        assertStmt("int x[3][4]; return sizeof(**x) + 1;", 5)
        assertStmt("int x[3][4]; return sizeof **x + 1;", 5)
        assertStmt("int x[3][4]; return sizeof(**x + 1);", 4)
        assertStmt("int x=1; return sizeof(x=2);", 4)
        assertStmt("int x=1; sizeof(x=2); return x;", 1)
    }

    @test
    def globalVars() {
        assertFns("int x; int main() { return x; }", 0)
        assertFns("int x; int main() { x=3; return x; }", 3)
        assertFns("int x; int y; int main() { x=3; y=4; return x+y; }", 7)
        assertFns("int x, y; int main() { x=3; y=4; return x+y; }", 7)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[0]; }", 0)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[1]; }", 1)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[2]; }", 2)
        assertFns("int x[4]; int main() { x[0]=0; x[1]=1; x[2]=2; x[3]=3; return x[3]; }", 3)

        assertFns("int x; int main() { return sizeof(x); }", 4)
        assertFns("int x[4]; int main() { return sizeof(x); }", 16)
    }

    @test
    def char() {
        assertFns("int main() { char x=1; return x; }", 1)
        assertFns("int main() { char x=1; char y=2; return x; }", 1)
        assertFns("int main() { char x=1; char y=2; return y; }", 2)

        assertFns("int main() { char x; return sizeof(x); }", 1)
        assertFns("int main() { char x[10]; return sizeof(x); }", 10)
        assertFns(
            "int sub_char(char a, char b, char c) { return a-b-c; }" +
                "int main() { return sub_char(7, 3, 3); } ",
            1)
    }

    @test
    def strlit() {
        assertStmt("return \"\"[0];", 0)
        assertStmt("return sizeof(\"\");", 1)

        assertStmt("return \"abc\"[0];", 97)
        assertStmt("return \"abc\"[1];", 98)
        assertStmt("return \"abc\"[2];", 99)
        assertStmt("return \"abc\"[3];", 0)
        assertStmt("return sizeof(\"abc\");", 4)
        assertStmt("return sizeof(\"abcdef\");", 7)

        assertStmt("return \"\\a\"[0];", 7)
        assertStmt("return \"\\b\"[0];", 8)
        assertStmt("return \"\\t\"[0];", 9)
        assertStmt("return \"\\n\"[0];", 10)
        assertStmt("return \"\\v\"[0];", 11)
        assertStmt("return \"\\f\"[0];", 12)
        assertStmt("return \"\\r\"[0];", 13)
        assertStmt("return \"\\e\"[0];", 27)

        assertStmt("return \"\\j\"[0];", 106)
        assertStmt("return \"\\k\"[0];", 107)
        assertStmt("return \"\\l\"[0];", 108)

        assertStmt("return \"\\ax\\ny\"[0];", 7)
        assertStmt("return \"\\ax\\ny\"[1];", 120)
        assertStmt("return \"\\ax\\ny\"[2];", 10)
        assertStmt("return \"\\ax\\ny\"[3];", 121)

        assertStmt("return \"\\0\"[0];", 0)
        assertStmt("return \"\\20\"[0];", 16)
        assertStmt("return \"\\101\"[0];", 65)
        assertStmt("return \"\\1500\"[0];", 104)

        assertStmt("return \"\\x00\"[0]; ", 0)
        assertStmt("return \"\\x77\"[0]; ", 119)
        assertStmt("return \"\\xA5\"[0]; ", 165)
        assertStmt("return \"\\x00ff\"[0]; ", 255)
    }
}
