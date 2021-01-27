package cjx.mat

import cj.Approximate
import cjx.mat.DeterminantSolver
import cjx.mat.Matrix

class MatrixTest {

    static val tolerance : Double = 1e-7

    def appx[T: Approximate & Repr](a: T, b: T) {
        Assert.approximate(a, b, tolerance)
    }

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

    @test
    def determinant() {

        # Some tests from the "Ray Tracing Challenge" book
        {
            # 2x2 matrix
            val a = Matrix(
                [1, 5],
                [-3, 2])
            appx(a.determinant(), 17)
            appx(slowDet(a), 17)
        }
        {
            # 3x3 matrix
            val a = Matrix(
                [1, 2, 6],
                [-5, 8, -4],
                [2, 6, 4])
            appx(a.determinant(), -196)
            appx(slowDet(a), -196)
        }
        {
            # 4x4 matrix
            val a = Matrix(
                [-2, -8, 3, 5],
                [-3, 1, 7, 3],
                [1, 2, -9, 6],
                [-6, 7, 7, -9])
            appx(a.determinant(), -4071)
            appx(slowDet(a), -4071)
        }
    }

    def slowDet(m: Matrix): Double = DeterminantSolver.solve(m)
}
