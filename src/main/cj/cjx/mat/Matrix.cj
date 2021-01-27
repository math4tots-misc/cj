package cjx.mat

import cj.Error
import cj.Float64Array

## A simple double precision floating point Matrix
class Matrix : Hash, Repr {
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

    def repr(self: Self): String = "Matrix(" + ", ".join(rows().map(row -> row.toList())) + ")"
}
