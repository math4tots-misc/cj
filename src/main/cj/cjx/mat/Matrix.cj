package cjx.mat

import cj.Approximate
import cjx.mat.DeterminantSolver
import cj.Error
import cj.Float64Array

## A simple double precision floating point Matrix
class Matrix : Hash, Approximate, Repr {
    ## Number of columns in this matrix
    val c : Int

    ## The raw numbers in this matrix
    val data : Float64Array

    ## Number of rows in this matrix
    def __get_r(self: Self): Int = data.size() // c

    @variadic def new(rows: List[List[Double]]): Self = {
        val r = rows.size()
        val c = rows[0].size()
        val data = Float64Array.withSize(r * c)
        var i = 0
        for row in rows {
            Assert.equal(row.size(), c)
            for x in row {
                data[i] = x
                i += 1
            }
        }
        __malloc(c, data)
    }

    def __getitem(self: Self, ri: Int, ci: Int): Double = data[ri * c + ci]
    def __setitem(self: Self, ri: Int, ci: Int, value: Double) = { data[ri * c + ci] = value }

    private def _checkDim(self: Self, other: Self, msg: String) {
        if c != other.c or data.size() != other.data.size() {
            throw Error(msg)
        }
    }

    private def _checkSquare(self: Self, msg: String) {
        if c != r {
            throw Error(msg)
        }
    }

    private def _pairwise(self: Self, other: Self, f: Fn[Double, Double, Double]): Self = {
        val data = data
        val odata = other.data
        val len = data.size()
        val out = Float64Array.withSize(len)
        for i = 0; i < len; i += 1 {
            out[i] = f.call(data[i], odata[i])
        }
        __malloc(c, out)
    }

    def __add(self: Self, other: Self): Self = {
        _checkDim(other, "Invalid dimensions for Matrix.__add")
        _pairwise(other, (a, b) -> a + b)
    }

    def __sub(self: Self, other: Self): Self = {
        _checkDim(other, "Invalid dimensions for Matrix.__sub")
        _pairwise(other, (a, b) -> a - b)
    }

    def __mul(self: Self, other: Self): Self = {
        if c != other.r {
            throw Error("Invalid dimensions for Matrix.__mul")
        }
        val data = data
        val odata = other.data
        val m = c
        val nr = r
        val nc = other.c
        val out = Float64Array.withSize(nr * nc)
        for ri = 0; ri < nr; ri += 1 {
            for ci = 0; ci < nc; ci += 1 {
                val i = ri * nc + ci
                for j = 0; j < m; j += 1 {
                    out[i] = out[i] + data[ri * m + j] + odata[j * nc + ci]
                }
            }
        }
        __malloc(nc, out)
    }

    def scale(self: Self, factor: Double): Self = __malloc(c, data.map(x -> x * factor))

    def __neg(self: Self): Self = scale(-1)

    def determinant(self: Self): Double = {
        _checkSquare("Non-square matrix found in determinant")
        val data = data

        # Some optimized cases are from gl-matrix sources (a JS library)
        switch (c) {
            case 4 = {
                val a00 = data[0]
                val a01 = data[1]
                val a02 = data[2]
                val a03 = data[3]
                val a10 = data[4]
                val a11 = data[5]
                val a12 = data[6]
                val a13 = data[7]
                val a20 = data[8]
                val a21 = data[9]
                val a22 = data[10]
                val a23 = data[11]
                val a30 = data[12]
                val a31 = data[13]
                val a32 = data[14]
                val a33 = data[15]

                val b0 = a00 * a11 - a01 * a10
                val b1 = a00 * a12 - a02 * a10
                val b2 = a01 * a12 - a02 * a11
                val b3 = a20 * a31 - a21 * a30
                val b4 = a20 * a32 - a22 * a30
                val b5 = a21 * a32 - a22 * a31
                val b6 = a00 * b5 - a01 * b4 + a02 * b3
                val b7 = a10 * b5 - a11 * b4 + a12 * b3
                val b8 = a20 * b2 - a21 * b1 + a22 * b0
                val b9 = a30 * b2 - a31 * b1 + a32 * b0

                a13 * b6 - a03 * b7 + a33 * b8 - a23 * b9
            }
            else = DeterminantSolver.solve(self)
        }
    }

    def rows(self: Self): List[Float64Array] = {
        val rs: List[Float64Array] = []
        for ri = 0; ri < r; ri += 1 {
            rs.add(Float64Array.withSize(c))
            for ci = 0; ci < c; ci += 1 {
                rs.last()[ci] = data[ri * c + ci]
            }
        }
        rs
    }

    def hash(self: Self): Int = (c, data).hash()

    def __eq(self: Self, other: Self): Bool = c == other.c and data == other.data

    def approximates(self: Self, other: Self, tolerance: Double): Bool = (
        c == other.c and data.approximates(other.data, tolerance))

    def repr(self: Self): String = "Matrix(" + ", ".join(rows().map(row -> row.toList())) + ")"
}
