package cj

## Test list operations
class Test02List {

    @test
    def literals() = {
        {
            val list: List[String] = []
            Assert.equal(list.size(), 0)
        }
    }

    @test
    def add() = {
        {
            val list = List[Int].empty()
            Assert.equal(list.size(), 0)
            list.add(15)
            Assert.equal(list, [15])
            Assert.equal(list.get(0), 15)
        }
    }

    @test
    def repr() = {
        # Self.print([true, true, false])
        Assert.equal("print " + [true, true, false].repr(), "print [true, true, false]")
        Assert.equal(Self.print([true, true, false]), "print [true, true, false]")
    }

    def print[T: Repr](t: T): String = "print " + t.repr()
}
