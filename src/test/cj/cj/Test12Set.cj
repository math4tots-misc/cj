package cj

import cj.IO

class Test12Set {

    @test
    def literal() = {
        val set = Set.of([1, 2, 3])
        Assert.equal(set, Set.of([3, 2, 1]))
    }

    @test
    def asKeys() = {
        val map = [Set.of([1]): "first", Set.of([1, 2]): "second"]
        Assert.equal("" + map, "[Set.of([1]): \"first\", Set.of([1, 2]): \"second\"]")
        Assert.equal(map.getOrNull(Set.of([2])), null)
        Assert.equal(map.getOrNull(Set.of([1])), null("first"))
    }
}
