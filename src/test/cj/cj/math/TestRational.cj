package cj.math

import cj.math.Rational

class TestRational {
    @test
    def constructor() {
        {
            val r = 2n / 4n
            Assert.equal(r, 1n / 2n)
            Assert.equal(r.toString(), "1/2")
            Assert.equal(r.repr(), "Rational(1, 2)")
            Assert.equal(r, 1n / 2)
            Assert.equal(r, Rational(1, 2))
        }
    }

    @test
    def ops() {
        {
            val a = 2n / 3
            val b = 3n / 4
            Assert.equal(a + b, Rational(17, 12))
            Assert.equal(a - b, -1n / 12)
            Assert.equal(a * b, 1n / 2)
            Assert.equal(a / b, 8n / 9)
        }
    }

    @test
    def truncdiv() {
        {
            val a = 8n / 1
            val b = 3n / 1
            Assert.equal(a // b, 2)
            Assert.equal((9n / 1) // b, 3)
        }
    }
}
