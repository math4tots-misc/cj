package cj

class Test02Numbers {

    @test
    def intOps() = {
        Assert.equal(21 + 42, 63)
        Assert.equal(21 - 42, -21)
        Assert.equal(21 * 42, 882)
        Assert.equal(21 % 42, 21)
        Assert.equal(21 // 42, 0)
        Assert.equal(21 / 42, 0.5)
        Assert.equal(+21, 21)
        Assert.equal(~21, -22)
    }
}
