package cj

import cj.Deque

class Test17Deque {
    @test
    def sample() {
        val d = Deque([1, 2, 3])
        Assert.equal(d.toList(), [1, 2, 3])
        Assert.equal(d.size(), 3)
        d.popleft()
        Assert.equal(d.toList(), [2, 3])
        Assert.equal(d.size(), 2)
        d.pop()
        Assert.equal(d.toList(), [2])
        Assert.equal(d.size(), 1)
        d.addleft(14)
        Assert.equal(d.toList(), [14, 2])
        Assert.equal(d.size(), 2)
    }
}
