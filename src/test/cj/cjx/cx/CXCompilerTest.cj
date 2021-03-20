package cjx.cx

import cjx.cx.CXCompiler

class CXCompilerTest {
    @test
    def sample() {
        Assert.equal(CXCompiler.compileAndRun(4), 4)
    }
}
