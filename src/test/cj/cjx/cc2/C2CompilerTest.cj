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
    }
}
