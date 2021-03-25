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

    def assertCode(expr: String, code: Int) {
        Assert.equal(runIntExpr(expr), code)
    }

    @test
    def sample0() {
        assertCode("5", 5)
        assertCode("-3", -3)
        assertCode("5+7", 12)
        assertCode("5-7", -2)
        assertCode("5+(5-7)", 3)
        assertCode("5*(5-7)", -10)
        assertCode("5+6*7", 47)
        assertCode("5*(9-6)", 15)
        assertCode("(3+5)/2", 4)
        assertCode("-10+20", 10)
        assertCode("- -10", 10)
        assertCode("- - +10", 10)
    }

    @test
    def sample1() {
        assertCode("0==1", 0)
        assertCode("42==42", 1)
        assertCode("0!=1", 1)
        assertCode("42!=42", 0)

        assertCode("0<1", 1)
        assertCode("1<1", 0)
        assertCode("2<1", 0)
        assertCode("0<=1", 1)
        assertCode("1<=1", 1)
        assertCode("2<=1", 0)

        assertCode("1>0", 1)
        assertCode("1>1", 0)
        assertCode("1>2", 0)
        assertCode("1>=0", 1)
        assertCode("1>=1", 1)
        assertCode("1>=2", 0)
    }
}
