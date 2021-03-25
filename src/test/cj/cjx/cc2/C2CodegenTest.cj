package cjx.cc2

import cjx.cc2.C2Codegen

class C2CodegenTest {

    @test
    def alignTo() {
        Assert.equal(C2Codegen.alignTo(0, 8), 0)
        Assert.equal(C2Codegen.alignTo(5, 8), 8)
        Assert.equal(C2Codegen.alignTo(9, 8), 16)
        Assert.equal(C2Codegen.alignTo(8, 8), 8)
        Assert.equal(C2Codegen.alignTo(16, 8), 16)
    }
}
