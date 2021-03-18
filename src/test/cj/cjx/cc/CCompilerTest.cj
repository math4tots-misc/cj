package cjx.cc

import cjx.cc.CCompiler

class CCompilerTest {

    def assertCode(source: String, code: Int) {
        Assert.equal(CCompiler.compileAndRunMain(source), code)
    }

    @test
    def returnCodes0() {
        assertCode("0;", 0)
        assertCode("-3;", -3)
        assertCode("5+7;", 12)
        assertCode("5-7;", -2)
        assertCode("5+(5-7);", 3)
        assertCode("5*(5-7);", -10)
        assertCode("5+6*7;", 47)
        assertCode("5*(9-6);", 15)
        assertCode("(3+5)/2;", 4)
        assertCode("-10+20;", 10)
        assertCode("- -10;", 10)
        assertCode("- - +10;", 10)
    }

    @test
    def returnCodes1() {
        assertCode("0==1;", 0)
        assertCode("42==42;", 1)
        assertCode("0!=1;", 1)
        assertCode("42!=42;", 0)

        assertCode("0<1;", 1)
        assertCode("1<1;", 0)
        assertCode("2<1;", 0)
        assertCode("0<=1;", 1)
        assertCode("1<=1;", 1)
        assertCode("2<=1;", 0)

        assertCode("1>0;", 1)
        assertCode("1>1;", 0)
        assertCode("1>2;", 0)
        assertCode("1>=0;", 1)
        assertCode("1>=1;", 1)
        assertCode("1>=2;", 0)

        assertCode("1; 2; 3;", 3)
    }

    @test
    def returnCodes2() {
        assertCode("a=3; a;", 3)
        assertCode("a=3; z=5; a+z;", 8)
        assertCode("a=b=3; a+b; ", 13)
    }
}
