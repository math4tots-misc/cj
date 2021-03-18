package cjx.cc

import cjx.cc.CCompiler

class CCompilerTest {

    @test
    def returnCodes() {
        Assert.equal(CCompiler.compileAndRunMain("0"), 0)
        Assert.equal(CCompiler.compileAndRunMain("-3"), -3)
        Assert.equal(CCompiler.compileAndRunMain("5+7"), 12)
        Assert.equal(CCompiler.compileAndRunMain("5-7"), -2)
        Assert.equal(CCompiler.compileAndRunMain("5+(5-7)"), 3)
        Assert.equal(CCompiler.compileAndRunMain("5*(5-7)"), -10)
        Assert.equal(CCompiler.compileAndRunMain("5+6*7"), 47)
        Assert.equal(CCompiler.compileAndRunMain("5*(9-6)"), 15)
        Assert.equal(CCompiler.compileAndRunMain("(3+5)/2"), 4)
    }
}
