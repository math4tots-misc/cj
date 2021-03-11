package cj

import cj.Map

class Test10Map {

    @test
    def repr() = {
        {
            val map = Map[Int, Int].empty()
            Assert.equal(map.repr(), "MapOf()")

            map[50] = 20
            Assert.equal(map.repr(), "MapOf(50: 20)")
            map[50] = 30
            Assert.equal(map.repr(), "MapOf(50: 30)")
            map[75] = 2
            Assert.equal(map.repr(), "MapOf(50: 30, 75: 2)")
        }
    }

    @test
    def literals() = {
        {
            val map = Map.of([(1, 2), (3, 4)])
            Assert.equal("" + map, "MapOf(1: 2, 3: 4)")
            Assert.equal(map, Map([1: 2, 3: 4]))
            Assert.equal(map, Map([3: 4, 1: 2]))
            Assert.that(map != Map([1: 2]))
            Assert.that(map != Map([1: 2, 3: 5]))
        }
    }

    @test
    def get() = {
        {
            val map = Map([1: "qwer", 2: "erty"])
            Assert.equal(map[1], "qwer")
            Assert.equal(map[2], "erty")
            Assert.that(1 in map)
            Assert.that(2 in map)
            Assert.that(3 not in map)
        }
    }
}
