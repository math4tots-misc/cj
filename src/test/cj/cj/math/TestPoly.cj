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
}
