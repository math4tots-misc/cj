package cj.math

import cjx.math.Poly1

class TestPoly {
    @test
    def add() {
        {
            val x = Poly1[Int].x
            Assert.equal("" + x, "x")
            Assert.equal("" + (x + x), "2x")
            Assert.equal("" + (x * x), "x2")
            Assert.equal("" + (x + x + x * x), "2x + x2")
        }
    }

    @test
    def apply() {
        {
            # x + x2
            val f = Poly1(0, 1, 1)
            Assert.equal(f.apply(1), 2)
            Assert.equal(f.apply(2), 6)
            Assert.equal(f.apply(3), 12)
            Assert.equal(f.apply(-3), 6)
        }
    }
}
