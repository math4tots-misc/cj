package cjx.cc

import cjx.cc.CCompiler

class CCompilerTest {

    @test
    def returnCodes0() {
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

    @test
    def returnCodes1() {
        Assert.equal(CCompiler.compileAndRunMain("0==1"), 0)
        Assert.equal(CCompiler.compileAndRunMain("42==42"), 1)
        Assert.equal(CCompiler.compileAndRunMain("0!=1"), 1)
        Assert.equal(CCompiler.compileAndRunMain("42!=42"), 0)

        Assert.equal(CCompiler.compileAndRunMain("0<1"), 1)
        Assert.equal(CCompiler.compileAndRunMain("1<1"), 0)
        Assert.equal(CCompiler.compileAndRunMain("2<1"), 0)
        Assert.equal(CCompiler.compileAndRunMain("0<=1"), 1)
        Assert.equal(CCompiler.compileAndRunMain("1<=1"), 1)
        Assert.equal(CCompiler.compileAndRunMain("2<=1"), 0)

        Assert.equal(CCompiler.compileAndRunMain("1>0"), 1)
        Assert.equal(CCompiler.compileAndRunMain("1>1"), 0)
        Assert.equal(CCompiler.compileAndRunMain("1>2"), 0)
        Assert.equal(CCompiler.compileAndRunMain("1>=0"), 1)
        Assert.equal(CCompiler.compileAndRunMain("1>=1"), 1)
        Assert.equal(CCompiler.compileAndRunMain("1>=2"), 0)
    }
}
