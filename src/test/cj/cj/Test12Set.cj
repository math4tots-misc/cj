package cj

import cj.IO

class Test12Set {

    @test
    def literal() = {
        val set = Set.of([1, 2, 3])
        Assert.equal(set, Set.of([3, 2, 1]))
        Assert.equal(set, Set([2, 3, 2, 1]))
    }

    @test
    def asKeys() = {
        val map = Map([Set.of([1]): "first", Set.of([1, 2]): "second"])
        Assert.equal("" + map, "MapOf(SetOf(1): \"first\", SetOf(1, 2): \"second\")")
        Assert.equal(map.getOrNull(Set.of([2])), null)
        Assert.equal(map.getOrNull(Set.of([1])), null("first"))
        Assert.equal(map.getOrNull(Set.__new([1, 2])), null("second"))
        Assert.equal(map.getOrNull(Set([1])), null("first"))
    }
}
