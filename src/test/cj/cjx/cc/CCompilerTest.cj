package cjx.cc

import cjx.cc.CCompiler

class CCompilerTest {

    @test
    def returnCodes() {
        Assert.equal(CCompiler.compileAndRunMain("0"), 0)
        Assert.equal(CCompiler.compileAndRunMain("-3"), -3)
    }
}
