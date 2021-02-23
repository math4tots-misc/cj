package cj

import cj.Float64Array

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
            Assert.equal(list[0], 15)
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
    def add2() {
        Assert.equal([1, 2, 3, 5, 6, 7], [1, 2, 3] + [5, 6, 7])
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

    @test
    def swap() {
        {
            val list = [1, 2]
            list.swap(0, 1)
            Assert.equal(list, [2, 1])
        }
    }

    @test
    def slice() {
        {
            val list = ["a", "b", "c", "d", "e", "f"]
            Assert.equal(list[:2], ["a", "b"])
            Assert.equal(list[2:], ["c", "d", "e", "f"])
            Assert.equal(list[2:4], ["c", "d"])
        }
        {
            val list = Float64Array(5.5, 6.6, 7.7, 8.8, 9.9, 1.1, 2.2, 3.3)
            Assert.equal(list[:2], Float64Array(5.5, 6.6))
            Assert.equal(list[2:], Float64Array(7.7, 8.8, 9.9, 1.1, 2.2, 3.3))
            Assert.equal(list[2:4], Float64Array(7.7, 8.8))
        }
    }

    @test
    def pop() {
        val list = [1, 2, 3]
        Assert.equal(list.pop(), 3)
        Assert.equal(list, [1, 2])
    }

    @test
    def addAll() {
        val list = ["a", "b", "c"]
        list.addAll(["x", "y", "z"])
        Assert.equal(list, ["a", "b", "c", "x", "y", "z"])
    }

    @test
    def sort() {
        {
            val list = [1, 2, 3, 4, 11, 111, 12, 22, 444]
            list.sort()
            Assert.equal(list, [1, 2, 3, 4, 11, 12, 22, 111, 444])
        }
        {
            val list = ["1", "2", "3", "4", "11", "111", "12", "22", "444"]
            list.sort()
            Assert.equal(list, ["1", "11", "111", "12", "2", "22", "3", "4", "444"])
        }
        {
            val set = Set(1, 3, 5, 7, 6, 4, 2)
            Assert.equal(set.sorted(), [1, 2, 3, 4, 5, 6, 7])
            Assert.equal(set, Set(1, 2, 3, 4, 5, 6, 7))
        }
    }

    @test
    def allAny() {
        Assert(List[Int]().all(x -> x))
        Assert(not List[String]().any(x -> x))
        Assert([1, 2, 3].all(x -> x))
        Assert(not [1, 0, 3].all(x -> x))
        Assert(not [0, 0, 0].all(x -> x))
        Assert([1, 2, 3].any(x -> x))
        Assert([1, 0, 3].any(x -> x))
        Assert(not [0, 0, 0].any(x -> x))
    }
}
