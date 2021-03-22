package cjx.cc

import cjx.cc.CCompiler

class CCompilerTest {

    def assertCode(source: String, code: Int) {
        Assert.equal(CCompiler.compileAndRunMain("int main() " + source), code)
    }

    def assert2(source: String, code: Int) {
        Assert.equal(CCompiler.compileAndRunMain(source), code)
    }

    @test
    def returnCodes0() {
        assertCode("{return 0;}", 0)
        assertCode("{return -3;}", -3)
        assertCode("{return 5+7;}", 12)
        assertCode("{return 5-7;}", -2)
        assertCode("{return 5+(5-7);}", 3)
        assertCode("{return 5*(5-7);}", -10)
        assertCode("{return 5+6*7;}", 47)
        assertCode("{return 5*(9-6);}", 15)
        assertCode("{return (3+5)/2;}", 4)
        assertCode("{return -10+20;}", 10)
        assertCode("{return - -10;}", 10)
        assertCode("{return - - +10;}", 10)
    }

    @test
    def returnCodes1() {
        assertCode("{return 0==1;}", 0)
        assertCode("{return 42==42;}", 1)
        assertCode("{return 0!=1;}", 1)
        assertCode("{return 42!=42;}", 0)

        assertCode("{return 0<1;}", 1)
        assertCode("{return 1<1;}", 0)
        assertCode("{return 2<1;}", 0)
        assertCode("{return 0<=1;}", 1)
        assertCode("{return 1<=1;}", 1)
        assertCode("{return 2<=1;}", 0)

        assertCode("{return 1>0;}", 1)
        assertCode("{return 1>1;}", 0)
        assertCode("{return 1>2;}", 0)
        assertCode("{return 1>=0;}", 1)
        assertCode("{return 1>=1;}", 1)
        assertCode("{return 1>=2;}", 0)
    }

    @test
    def returnCodes2() {
        assertCode("{int a=3; return a;}", 3)
        assertCode("{int a=3; int z=5; return a+z;}", 8)
        assertCode("{int a; int b; a=b=3; return a+b; } ", 6)

        assertCode("{1; 2; return 3;}", 3)
        assertCode("{ {1; {2;} return 3;} }", 3)
        assertCode("{ ;;; return 5; }", 5)
    }

    @test
    def ifStmt() {
        assertCode("{ if (0) return 2; return 3; }", 3)
        assertCode("{ if (1-1) return 2; return 3; }", 3)
        assertCode("{ if (1) return 2; return 3; }", 2)
        assertCode("{ if (2-1) return 2; return 3; }", 2)
        assertCode("{ if (0) { 1; 2; return 3; } else { return 4; } }", 4)
        assertCode("{ if (1) { 1; 2; return 3; } else { return 4; } }", 3)
    }

    @test
    def forStmt() {
        assertCode("{ int i=0, j=0; for (i=0; i<=10; i=i+1) j=i+j; return j; }", 55)
        assertCode("{ for (;;) {return 3;} return 5; }", 3)
        assertCode("{ int i=0; while(i<10) { i=i+1; } return i; }", 10)
    }

    @test
    def addr() {
        assertCode("{ int x=3; return *&x; }", 3)
        assertCode("{ int x=3; int *y=&x; int **z=&y; return **z; }", 3)
        assertCode("{ int x=3; int y=5; return *(&x+1); }", 5)
        assertCode("{ int x=3; int y=5; return *(&y-1); }", 3)
        assertCode("{ int x=3; int y=5; return *(&x-(-1)); }", 5)
        assertCode("{ int x=3; int y=&x; *y=5; return x; }", 5)
        assertCode("{ int x=3; int y=5; *(&x+1)=7; return y; }", 7)
        assertCode("{ int x=3; int y=5; *(&y-1)=7; return x; }", 7)
        assertCode("{ int x=3; return (&x+2)-&x+3; }", 5)
    }

    @test
    def funcs() {
        assert2("int foo() { return 5; } int main() { return foo(); }", 5)
    }
}
