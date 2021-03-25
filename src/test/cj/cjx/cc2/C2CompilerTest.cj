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

    @test
    def sample0() {
        Assert.equal(runIntExpr("5"), 5)
        Assert.equal(runIntExpr("-3"), -3)
        Assert.equal(runIntExpr("5+7"), 12)
        Assert.equal(runIntExpr("5-7"), -2)
        Assert.equal(runIntExpr("5+(5-7)"), 3)
        Assert.equal(runIntExpr("5*(5-7)"), -10)
        Assert.equal(runIntExpr("5+6*7"), 47)
        Assert.equal(runIntExpr("5*(9-6)"), 15)
        Assert.equal(runIntExpr("(3+5)/2"), 4)
        Assert.equal(runIntExpr("-10+20"), 10)
        Assert.equal(runIntExpr("- -10"), 10)
        Assert.equal(runIntExpr("- - +10"), 10)
    }
}
