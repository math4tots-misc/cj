package cj.math

import cj.Math

class MathTest {
    @test
    def random() {
        val x = Math.random()
        Assert(x >= 0 and x <= 1)
    }
}
