package cj.math

class IntTest {
    @test
    def roundUp() {
        Assert.equal((0).roundUp(8), 0)
        Assert.equal((5).roundUp(8), 8)
        Assert.equal((9).roundUp(8), 16)
        Assert.equal((8).roundUp(8), 8)
        Assert.equal((16).roundUp(8), 16)
    }
}
