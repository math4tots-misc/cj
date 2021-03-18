package cjx.cc

import cjx.cc.CCompiler

class CCompilerTest {

    def assertCode(source: String, code: Int) {
        Assert.equal(CCompiler.compileAndRunMain(source), code)
    }

    @test
    def returnCodes0() {
        assertCode("return 0;", 0)
        assertCode("return -3;", -3)
        assertCode("return 5+7;", 12)
        assertCode("return 5-7;", -2)
        assertCode("return 5+(5-7);", 3)
        assertCode("return 5*(5-7);", -10)
        assertCode("return 5+6*7;", 47)
        assertCode("return 5*(9-6);", 15)
        assertCode("return (3+5)/2;", 4)
        assertCode("return -10+20;", 10)
        assertCode("return - -10;", 10)
        assertCode("return - - +10;", 10)
    }

    @test
    def returnCodes1() {
        assertCode("return 0==1;", 0)
        assertCode("return 42==42;", 1)
        assertCode("return 0!=1;", 1)
        assertCode("return 42!=42;", 0)

        assertCode("return 0<1;", 1)
        assertCode("return 1<1;", 0)
        assertCode("return 2<1;", 0)
        assertCode("return 0<=1;", 1)
        assertCode("return 1<=1;", 1)
        assertCode("return 2<=1;", 0)

        assertCode("return 1>0;", 1)
        assertCode("return 1>1;", 0)
        assertCode("return 1>2;", 0)
        assertCode("return 1>=0;", 1)
        assertCode("return 1>=1;", 1)
        assertCode("return 1>=2;", 0)

        assertCode("1; 2; return 3;", 3)
    }

    @test
    def returnCodes2() {
        assertCode("a=3; return a;", 3)
        assertCode("a=3; z=5; return a+z;", 8)
        assertCode("a=b=3; return a+b; ", 6)
    }
}
