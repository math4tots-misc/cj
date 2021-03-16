package cj.classes

class UnionTest {

    union Union {
        case zero
        case one(Int)
        case two(String, Union)
    }

    union NoArgUnion {
        case a
        case b
        case c
    }

    @test
    def tags() {
        Assert.equal(tag!(Union.zero), 0)
        Assert.equal(tag!(Union.one(5)), 1)
        Assert.equal(tag!(Union.two("hi", Union.zero)), 2)
        Assert.equal(tag!(NoArgUnion.a), 0)
        Assert.equal(tag!(NoArgUnion.b), 1)
        Assert.equal(tag!(NoArgUnion.c), 2)

        Assert.equal(tag!(Union, zero), 0)
        Assert.equal(tag!(Union, one), 1)
        Assert.equal(tag!(Union, two), 2)
        Assert.equal(tag!(NoArgUnion, a), 0)
        Assert.equal(tag!(NoArgUnion, b), 1)
        Assert.equal(tag!(NoArgUnion, c), 2)
    }
}
