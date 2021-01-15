package cj

## Test list operations
class Test03List {

    @test
    def literals() = {
        {
            val list: List[String] = []
            Assert.equal(list.size(), 0)
        }
        {
            val list = [
                if true { 15 } else { 20 },
                if false { 30 } else { 75 },
            ]
            Assert.equal(list, [15, 75])
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
        {
            var list = List[Int].empty()
            if (5 < 10) {
                list.add(66)
            }
            if (10 > 5) {
                list.add(123)
            }
            if (5 > 10) {
                list.add(777)
            }
            Assert.equal(list, [66, 123])
        }
    }

    @test
    def repr() = {
        # Self.print([true, true, false])
        Assert.equal("print " + [true, true, false].repr(), "print [true, true, false]")
        Assert.equal(Self.print([true, true, false]), "print [true, true, false]")
    }

    def print[T: Repr](t: T): String = "print " + t.repr()

    @test
    def iter() = {
        {
            val list = ["asdf", "qwer", "zxcv"]
            val iter = list.iter()
            Assert.equal(iter.next(), null("asdf"))
            Assert.equal(iter.next(), null("qwer"))
            Assert.equal(iter.next(), null("zxcv"))
            Assert.equal(iter.next(), null)
        }
    }

    @test
    def removeIndex() = {
        {
            val list = ["asdf", "erty", "cvbn"]
            Assert.equal(list.removeIndex(1), "erty")
            Assert.equal(list, ["asdf", "cvbn"])
        }
    }

    @test
    def toSetAndToMap() = {
        {
            val set = [1, 2, 3].toSet()
            Assert.equal(set, Set(2, 3, 1))
        }
        {
            val map = [1: "a", 2: "b"].toMap()
            Assert.equal(map, Map(2: "b", 1: "a"))
        }
    }
}
