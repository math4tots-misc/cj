package cjx.mat

import cjx.mat.Matrix

class MatrixTest {

    @test
    def repr() = {
        {
            val m = Matrix(
                [1, 2, 3],
                [4, 5, 6])
            Assert.equal(m.repr(), "Matrix([1, 2, 3], [4, 5, 6])")
            Assert.equal(m, m)
            Assert.equal(m, Matrix([1, 2, 3], [4, 5, 6]))
            Assert.equal(m.r, 2)
            Assert.equal(m.c, 3)
            val m2 = m + Matrix([2, 2, 2], [3, 3, 3])
            Assert.equal(m2.repr(), "Matrix([3, 4, 5], [7, 8, 9])")
        }
    }

    @test
    def multiply() = {
        {
            val a = Matrix([1, 2, 3], [4, 5, 6])
            val b = Matrix([8, 9], [10, 11], [12, 13])
            Assert.equal(a * b, Matrix([36, 39], [45, 48]))
        }
    }
}
