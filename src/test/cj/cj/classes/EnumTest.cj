package cj.classes

class EnumTest {

    enum {
        zero
        one
        two
        three
        thirteen = 13
        fourteen
    }

    enum { x = 5; y; z }

    @test
    def values() {
        Assert.equal(zero, 0)
        Assert.equal(one, 1)
        Assert.equal(two, 2)
        Assert.equal(three, 3)
        Assert.equal(thirteen, 13)
        Assert.equal(fourteen, 14)
        Assert.equal(x, 5)
        Assert.equal(y, 6)
        Assert.equal(z, 7)
    }
}
