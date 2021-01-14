package cj

import cj.Map

class Test10Map {

    @test
    def repr() = {
        {
            val map = Map[Int, Int].empty()
            Assert.equal(map.repr(), "[:]")

            map.set(50, 20)
            Assert.equal(map.repr(), "[50: 20]")
            map.set(50, 30)
            Assert.equal(map.repr(), "[50: 30]")
            map.set(75, 2)
            Assert.equal(map.repr(), "[50: 30, 75: 2]")
        }
    }

    @test
    def literals() = {
        {
            val map = Map.of([(1, 2), (3, 4)])
            Assert.equal("" + map, "[1: 2, 3: 4]")
            Assert.equal(map, [1: 2, 3: 4])
            Assert.equal(map, [3: 4, 1: 2])
            Assert.that(map != [1: 2])
            Assert.that(map != [1: 2, 3: 5])
        }
    }
}
