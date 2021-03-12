package cjx.math.mat

import cjx.math.mat.MatxOf
import cjx.math.mat.InverseMatrixSolver
import cj.Approximate
import cjx.math.mat.DeterminantSolver
import cjx.math.mat.Matx

class MatrixTest {
    # Some tests from the "Ray Tracer Challenge" book

    static val tolerance : Double = 1e-7

    def appx[T: Approximate & Repr](a: T, b: T) {
        Assert.approximate(a, b, tolerance)
    }

    def slowDet(m: Matx): Double = DeterminantSolver.solve(m)
    def slowInv(m: Matx): Nullable[Matx] = InverseMatrixSolver.invert(m)

    @test
    def repr() = {
        {
            val m = MatxOf(
                [1, 2, 3],
                [4, 5, 6])
            Assert.equal(m.repr(), "MatxOf([1, 2, 3], [4, 5, 6])")
            Assert.equal(m, m)
            Assert.equal(m, MatxOf([1, 2, 3], [4, 5, 6]))
            Assert.equal(m.r, 2)
            Assert.equal(m.c, 3)
            val m2 = m + MatxOf([2, 2, 2], [3, 3, 3])
            Assert.equal(m2.repr(), "MatxOf([3, 4, 5], [7, 8, 9])")
        }
    }

    @test
    def multiply1() = {
        {
            val a = MatxOf([1, 2, 3], [4, 5, 6])
            val b = MatxOf([8, 9], [10, 11], [12, 13])
            Assert.equal(a * b, MatxOf([64, 70], [154, 169]))
        }
    }

    @test
    def identity() = {
        Assert.equal(Matx.identity(3), MatxOf(
            [1, 0, 0],
            [0, 1, 0],
            [0, 0, 1],
        ))
    }

    @test
    def multiply2() {
        {
            # Multiplying two matrices
            val a = MatxOf(
                [1, 2, 3, 4],
                [5, 6, 7, 8],
                [9, 8, 7, 6],
                [5, 4, 3, 2])
            val b = MatxOf(
                [-2, 1, 2, 3],
                [3, 2, 1, -1],
                [4, 3, 6, 5],
                [1, 2, 7, 8])
            Assert.equal(a * b, MatxOf(
                [20, 22, 50, 48],
                [44, 54, 114, 108],
                [40, 58, 110, 102],
                [16, 26, 46, 42]))
        }
        {
            # A matrix multiplied by a tuple
            val a = MatxOf(
                [1, 2, 3, 4],
                [2, 4, 4, 2],
                [8, 6, 4, 1],
                [0, 0, 0, 1])
            val b = Matx.fromColumns([[1, 2, 3, 1]])
            Assert.equal(a * b, Matx.fromColumns([[18, 24, 33, 1]]))
        }
        {
            # Multiplying a matrix by the identity matrix
            val a = MatxOf(
                [1, 2, 3, 4],
                [2, 4, 4, 2],
                [8, 6, 4, 1],
                [0, 0, 0, 1])
            Assert.equal(a * Matx.identity(4), a)
        }
        {
            # Multiplying the identity matrix by a tuple
            val a = Matx.fromColumns([[1, 2, 3, 4]])
            Assert.equal(Matx.identity(4) * a, a)
        }
    }

    @test
    def determinant() {
        {
            # 2x2 matrix
            val a = MatxOf(
                [1, 5],
                [-3, 2])
            appx(a.determinant(), 17)
            appx(slowDet(a), 17)
        }
        {
            # 3x3 matrix
            val a = MatxOf(
                [1, 2, 6],
                [-5, 8, -4],
                [2, 6, 4])
            appx(a.determinant(), -196)
            appx(slowDet(a), -196)
        }
        {
            # 4x4 matrix
            val a = MatxOf(
                [-2, -8, 3, 5],
                [-3, 1, 7, 3],
                [1, 2, -9, 6],
                [-6, 7, 7, -9])
            appx(a.determinant(), -4071)
            appx(slowDet(a), -4071)
        }
    }

    @test
    def transpose() {
        {
            val a = MatxOf(
                [0, 9, 3, 0],
                [9, 8, 0, 8],
                [1, 8, 5, 3],
                [0, 0, 5, 8])
            Assert.equal(a.transpose(), MatxOf(
                [0, 9, 1, 0],
                [9, 8, 8, 0],
                [3, 0, 5, 5],
                [0, 8, 3, 8]))
        }
        {
            val i = Matx.identity(4)
            Assert.equal(i.transpose(), i)
        }
    }

    @test
    def inverse() {
        {
            # Testing an invertible matrix for invertibility
            val a = MatxOf(
                [6, 4, 4, 4],
                [5, 5, 7, 6],
                [4, -9, 3, -7],
                [9, 1, 7, -6])
            appx(a.determinant(), -2120)
            appx(slowDet(a), -2120)
            Assert.that(a.isInvertible())
        }
        {
            # Testing a noninvertible matrix for invertibility
            val a = MatxOf(
                [-4, 2, -2, -3],
                [9, 6, 2, 6],
                [0, -5, 1, -5],
                [0, 0, 0, 0])
            appx(a.determinant(), 0)
            appx(slowDet(a), 0)
            Assert.that(not a.isInvertible())
        }
        {
            # Calculating the inverse of a matrix
            val a = MatxOf(
                [-5, 2, 6, -8],
                [1, -5, 1, 8],
                [7, 7, -6, -7],
                [1, -3, 7, 4])
            val b = a.inverse().get()
            appx(a.determinant(), 532)
            appx(b[3, 2], -160.0/532)
            appx(b[2, 3], 105.0/532)

            val expectedB = MatxOf(
                [ 0.21805,  0.45113,  0.24060, -0.04511],
                [-0.80827, -1.45677, -0.44361,  0.52068],
                [-0.07895, -0.22368, -0.05263,  0.19737],
                [-0.52256, -0.81391, -0.30075,  0.30639])

            Assert.approximate(b, expectedB, 0.00001)
            Assert.approximate(slowInv(a).get(), expectedB, 0.00001)
        }
        {
            # Calculating the inverse of another matrix
            val a = MatxOf(
                [8, -5, 9, 2],
                [7, 5, 6, 1],
                [-6, 0, 9, 6],
                [-3, 0, -9, -4])
            val b = a.inverse().get()

            val expectedB = MatxOf(
                [-0.15385, -0.15385, -0.28205, -0.53846],
                [-0.07692,  0.12308,  0.02564,  0.03077],
                [ 0.35897,  0.35897,  0.43590,  0.92308],
                [-0.69231, -0.69231, -0.76923, -1.92308])

            Assert.approximate(b, expectedB, 0.00001)
            Assert.approximate(slowInv(a).get(), expectedB, 0.00001)
        }
        {
            # Calculating the inverse of a third matrix
            val a = MatxOf(
                [ 9,  3,  0,  9],
                [-5, -2, -6, -3],
                [-4,  9,  6,  4],
                [-7,  6,  6,  2])
            val b = a.inverse().get()

            val expectedB = MatxOf(
                [-0.04074, -0.07778,  0.14444, -0.22222],
                [-0.07778,  0.03333,  0.36667, -0.33333],
                [-0.02901, -0.14630, -0.10926,  0.12963],
                [ 0.17778,  0.06667, -0.26667,  0.33333])

            Assert.approximate(b, expectedB, 0.00001)
            Assert.approximate(slowInv(a).get(), expectedB, 0.00001)
        }
        {
            val a = MatxOf(
                [ 3, -9,  7, 3],
                [ 3, -8,  2, -9],
                [-4,  4,  4,  1],
                [-6,  5, -1,  1])
            val b = MatxOf(
                [ 8,  2,  2,  2],
                [ 3, -1,  7,  0],
                [ 7,  0,  5,  4],
                [ 6, -2,  0,  5])
            val c = a * b
            appx(b * slowInv(b).get(), Matx.identity(4))
            appx(slowInv(b).get() * b, Matx.identity(4))
            appx(c * slowInv(b).get(), a)
            appx(b * b.inverse().get(), Matx.identity(4))
            appx(b.inverse().get() * b, Matx.identity(4))
            appx(c * b.inverse().get(), a)
        }
        {
            # Invert a 3x3 matrix
            val a = MatxOf(
                [ 9,  3,  9],
                [-5, -2, -3],
                [-4,  9,  4])
            val b = a.inverse().get()

            val expectedB = MatxOf(
                [-0.09048, -0.32857, -0.04286],
                [-0.15238, -0.34286,  0.08571],
                [ 0.25238,  0.44286,  0.01429])

            Assert.approximate(b, expectedB, 0.00001)
            Assert.approximate(slowInv(a).get(), expectedB, 0.00001)
        }
        {
            # Invert a 2x2 matrix
            val a = MatxOf(
                [ 3,  9],
                [-2, -3])
            val b = a.inverse().get()

            val expectedB = MatxOf(
                [-0.33333, -1.00000],
                [ 0.22222,  0.33333])

            Assert.approximate(b, expectedB, 0.00001)
            Assert.approximate(slowInv(a).get(), expectedB, 0.00001)
        }
    }

}
