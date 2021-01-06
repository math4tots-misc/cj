package cj

import cj.Assert

class Test01 {

    @test
    def sanity() = {
        Assert.equal(1, 1)
    }

    @test
    def arithmetic() = {
        Assert.equal(1 + 1, 2)
        Assert.equal(2 * 7, 14)
    }

    @test
    def list() = {
        val list = [1, 2, 3]
        Assert.equal(list, list)
        Assert.equal(list, [1, 2, 3])
        Assert.that(list != [3, 2, 1])
    }
}
