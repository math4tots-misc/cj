package cj

class Test15BigInt {
    @test
    def sample() {
        {
            val x = 15n
            Assert.equal(x, x)
            Assert.equal(x, 15n)
            Assert.equal(x, 3n + 12n)
            Assert.that(x != 14n)
        }
    }

    @test
    def repr() {
        val x = -42n
        Assert.equal(x.toString(), "-42")
        Assert.equal(x.repr(), "-42n")
        val y = 9876n
        Assert.equal(y.toString(), "9876")
        Assert.equal(y.repr(), "9876n")
    }

    @test
    def largeValues() {
        {
            val x = 10n.ipow(50)
            Assert.equal(x.toString(), "1" + "0" * 50)
        }
    }
}
