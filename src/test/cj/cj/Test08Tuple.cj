package cj

class Test08Tuple {
    @test
    def samples() = {
        {
            val tuple = (1, 2.2, "three")
            Assert.equal(tuple.get0(), 1)
            Assert.equal(tuple.get1(), 2.2)
            Assert.equal(tuple.get2(), "three")
        }
        {
            val tuple = Self.returnPair()
            Assert.equal(tuple.get0(), 1)
            Assert.equal(tuple.get1(), "two")
        }
    }

    def returnPair(): Tuple[Int, String] = (1, "two")

    @test
    def assignment() = {
        {
            val (a, b) = Self.returnPair()
            Assert.equal(a, 1)
            Assert.equal(b, "two")
        }
    }
}
