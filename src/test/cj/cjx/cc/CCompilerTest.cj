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
    }
}
