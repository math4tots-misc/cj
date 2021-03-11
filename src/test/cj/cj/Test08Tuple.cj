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

    @test
    def repr() {
        Assert.equal((1, 2).repr(), "(1, 2)")
        Assert.equal((1, 2, 3).repr(), "(1, 2, 3)")
        Assert.equal((1, 2, 3, 4).repr(), "(1, 2, 3, 4)")
    }

    @test
    def eq() {
        {
            val t2 = (1, "hello")
            Assert.that(t2 < (2, "hello"))
            Assert.that(not (t2 < (0, "hello")))
            Assert.that(not (t2 < (1, "hello")))
            Assert.that(t2 <= (1, "hello"))
            Assert.that(t2 < (1, "zzz"))
        }
        {
            val t3 = (1, "hello", "x")
            Assert.that(t3 < (2, "hello", "x"))
            Assert.that(not (t3 < (0, "hello", "x")))
            Assert.that(not (t3 < (1, "hello", "x")))
            Assert.that(t3 <= (1, "hello", "x"))
            Assert.that(t3 < (1, "hello", "z"))
        }
        {
            val t4 = (1, "hello", "x", "y")
            Assert.that(t4 < (2, "hello", "x", "y"))
            Assert.that(not (t4 < (0, "hello", "x", "y")))
            Assert.that(not (t4 < (1, "hello", "x", "y")))
            Assert.that(t4 <= (1, "hello", "x", "y"))
            Assert.that(t4 < (1, "hello", "x", "z"))
        }
    }

    @test
    def hash() {
        {
            val map = Map((1, 2): "first")
            Assert.equal(map.size(), 1)
            Assert.equal(map[(1, 2)], "first")
            Assert.that((2, 1) not in map)
            Assert.that((5, 5) not in map)
            Assert.that((1, 2) in map)
            map[(2, 1)] = "second"
            Assert.that((2, 1) in map)
            Assert.that((1, 2) in map)
            Assert.equal(map[(2, 1)], "second")
            Assert.equal(map.size(), 2)
        }
        {
            val map = Map((1, 2, 3): "first")
            Assert.equal(map.size(), 1)
            Assert.equal(map[(1, 2, 3)], "first")
            Assert.that((3, 2, 1) not in map)
            Assert.that((5, 5, 5) not in map)
            Assert.that((1, 2, 3) in map)
            map[(3, 2, 1)] = "second"
            Assert.that((3, 2, 1) in map)
            Assert.that((1, 2, 3) in map)
            Assert.equal(map[(3, 2, 1)], "second")
            Assert.equal(map.size(), 2)
        }
        {
            val map = Map((1, 2, 3, 4): "first")
            Assert.equal(map.size(), 1)
            Assert.equal(map[(1, 2, 3, 4)], "first")
            Assert.that((4, 3, 2, 1) not in map)
            Assert.that((5, 5, 5, 5) not in map)
            Assert.that((1, 2, 3, 4) in map)
            map[(4, 3, 2, 1)] = "second"
            Assert.that((4, 3, 2, 1) in map)
            Assert.that((1, 2, 3, 4) in map)
            Assert.equal(map[(4, 3, 2, 1)], "second")
            Assert.equal(map.size(), 2)
        }
    }
}
