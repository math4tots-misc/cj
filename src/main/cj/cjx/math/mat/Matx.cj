package cjx.math.mat

import cj.Float32Array
import cjx.math.mat.InverseMatrixSolver
import cj.Approximate
import cjx.math.mat.DeterminantSolver
import cj.Error
import cj.Float64Array

## A simple double precision floating point Matx
class Matx : Hash, Approximate, Repr {
    ## Number of columns in this matrix
    val c : Int

    ## The raw numbers in this matrix
    val data : Float64Array

    ## Number of rows in this matrix
    def __get_r(self: Self): Int = data.size() // c

    @variadic def __new(rows: List[List[Double]]): Self = fromRows(rows)

    def _fromParts(c: Int, data: Float64Array): Self = __malloc(c, data)

    def fromColumns(columns: List[List[Double]]): Self = {
        val c = columns.size()
        val r = columns[0].size()
        val data = Float64Array.withSize(r * c)
        var ci = 0
        for column in columns {
            var ri = 0
            for x in column {
                data[ri * c + ci] = x
                ri++
            }
            ci++
        }
        __malloc(c, data)
    }

    def fromRows(rows: List[List[Double]]): Self = {
        val r = rows.size()
        val c = rows[0].size()
        val data = Float64Array.withSize(r * c)
        var i = 0
        for row in rows {
            Assert.equal(row.size(), c)
            for x in row {
                data[i] = x
                i++
            }
        }
        __malloc(c, data)
    }

    def fromRowArrays(rows: List[Float64Array]): Self = {
        val r = rows.size()
        val c = rows[0].size()
        val data = Float64Array.withSize(r * c)
        var i = 0
        for row in rows {
            Assert.equal(row.size(), c)
            for x in row {
                data[i] = x
                i++
            }
        }
        __malloc(c, data)
    }

    def identity(n: Int): Self = {
        val data = Float64Array.withSize(n * n)
        for i = 0; i < n; i++ {
            data[i * n + i] = 1
        }
        __malloc(n, data)
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
        for i = 0; i < len; i++ {
            out[i] = f.call(data[i], odata[i])
        }
        __malloc(c, out)
    }

    def __add(self: Self, other: Self): Self = {
        _checkDim(other, "Invalid dimensions for Matx.__add")
        _pairwise(other, (a, b) -> a + b)
    }

    def __sub(self: Self, other: Self): Self = {
        _checkDim(other, "Invalid dimensions for Matx.__sub")
        _pairwise(other, (a, b) -> a - b)
    }

    def __mul(self: Self, other: Self): Self = {
        if c != other.r {
            throw Error("Invalid dimensions for Matx.__mul")
        }
        val data = data
        val odata = other.data
        val m = c
        val nr = r
        val nc = other.c
        val out = Float64Array.withSize(nr * nc)
        for ri = 0; ri < nr; ri++ {
            for ci = 0; ci < nc; ci++ {
                val i = ri * nc + ci
                for j = 0; j < m; j++ {
                    out[i] = out[i] + data[ri * m + j] * odata[j * nc + ci]
                }
            }
        }
        __malloc(nc, out)
    }

    def scale(self: Self, factor: Double): Self = __malloc(c, data.map(x -> x * factor))

    def __neg(self: Self): Self = scale(-1)

    def isInvertible(self): Bool = self.determinant() != 0

    def isSquare(self): Bool = c == r

    def transpose(self): Self = {
        val c = c
        val r = r
        val data = data
        val nr = c
        val nc = r
        val out = Float64Array.withSize(nr * nc)
        var i = 0
        for ci = 0; ci < c; ci++ {
            for ri = 0; ri < r; ri++ {
                out[i] = data[ri * c + ci]
                i++
            }
        }
        __malloc(nc, out)
    }

    def determinant(self: Self): Double = {
        _checkSquare("Non-square matrix found in determinant")
        val data = data

        # Some optimized cases are from github.com/toji/gl-matrix
        switch c {
            case 1 = data[0]
            case 2 = data[0] * data[3] - data[2] * data[1]
            case 3 = {
                val a00 = data[0]
                val a01 = data[1]
                val a02 = data[2]
                val a10 = data[3]
                val a11 = data[4]
                val a12 = data[5]
                val a20 = data[6]
                val a21 = data[7]
                val a22 = data[8]
                (
                    a00 * (a22 * a11 - a12 * a21) +
                    a01 * (-a22 * a10 + a12 * a20) +
                    a02 * (a21 * a10 - a11 * a20))
            }
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

    def inverse(self): Nullable[Self] = {
        _checkSquare("Non-square matrix found in inverse")
        val data = data

        # Some optimized cases are from github.com/toji/gl-matrix
        switch c {
            case 1 = if data[0] == 0 { null } else { null(__malloc(1, Float64Array(1.0 / data[0]))) }
            case 2 = {
                val a0 = data[0]
                val a1 = data[1]
                val a2 = data[2]
                val a3 = data[3]
                val det = a0 * a3 - a2 * a1
                if not det {
                    return null
                }
                val idet = 1.0 / det
                null(__malloc(2, Float64Array(
                    a3 * idet,
                    -a1 * idet,
                    -a2 * idet,
                    a0 * idet)))
            }
            case 3 = {
                val a00 = data[0]
                val a01 = data[1]
                val a02 = data[2]
                val a10 = data[3]
                val a11 = data[4]
                val a12 = data[5]
                val a20 = data[6]
                val a21 = data[7]
                val a22 = data[8]
                val b01 = a22 * a11 - a12 * a21
                val b11 = -a22 * a10 + a12 * a20
                val b21 = a21 * a10 - a11 * a20
                val det = a00 * b01 + a01 * b11 + a02 * b21
                if not det {
                    return null
                }
                val idet = 1.0 / det
                val out = Float64Array(
                    b01 * idet,
                    (-a22 * a01 + a02 * a21) * idet,
                    (a12 * a01 - a02 * a11) * idet,
                    b11 * idet,
                    (a22 * a00 - a02 * a20) * idet,
                    (-a12 * a00 + a02 * a10) * idet,
                    b21 * idet,
                    (-a21 * a00 + a01 * a20) * idet,
                    (a11 * a00 - a01 * a10) * idet)
                null(__malloc(3, out))
            }
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

                val b00 = a00 * a11 - a01 * a10
                val b01 = a00 * a12 - a02 * a10
                val b02 = a00 * a13 - a03 * a10
                val b03 = a01 * a12 - a02 * a11
                val b04 = a01 * a13 - a03 * a11
                val b05 = a02 * a13 - a03 * a12
                val b06 = a20 * a31 - a21 * a30
                val b07 = a20 * a32 - a22 * a30
                val b08 = a20 * a33 - a23 * a30
                val b09 = a21 * a32 - a22 * a31
                val b10 = a21 * a33 - a23 * a31
                val b11 = a22 * a33 - a23 * a32

                val det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06
                if not det {
                    return null
                }
                val idet = 1.0 / det
                val out = Float64Array(
                    (a11 * b11 - a12 * b10 + a13 * b09) * idet,
                    (a02 * b10 - a01 * b11 - a03 * b09) * idet,
                    (a31 * b05 - a32 * b04 + a33 * b03) * idet,
                    (a22 * b04 - a21 * b05 - a23 * b03) * idet,
                    (a12 * b08 - a10 * b11 - a13 * b07) * idet,
                    (a00 * b11 - a02 * b08 + a03 * b07) * idet,
                    (a32 * b02 - a30 * b05 - a33 * b01) * idet,
                    (a20 * b05 - a22 * b02 + a23 * b01) * idet,
                    (a10 * b10 - a11 * b08 + a13 * b06) * idet,
                    (a01 * b08 - a00 * b10 - a03 * b06) * idet,
                    (a30 * b04 - a31 * b02 + a33 * b00) * idet,
                    (a21 * b02 - a20 * b04 - a23 * b00) * idet,
                    (a11 * b07 - a10 * b09 - a12 * b06) * idet,
                    (a00 * b09 - a01 * b07 + a02 * b06) * idet,
                    (a31 * b01 - a30 * b03 - a32 * b00) * idet,
                    (a20 * b03 - a21 * b01 + a22 * b00) * idet)

                null(__malloc(4, out))
            }
            else = InverseMatrixSolver.invert(self)
        }
    }

    def rows(self: Self): List[Float64Array] = {
        val rs: List[Float64Array] = []
        for ri = 0; ri < r; ri++ {
            rs.add(data[ri * c:(ri + 1) * c])
        }
        rs
    }

    def hash(self: Self): Int = (c, data).hash()

    def __eq(self: Self, other: Self): Bool = c == other.c and data == other.data

    def approximates(self: Self, other: Self, tolerance: Double): Bool = (
        c == other.c and data.approximates(other.data, tolerance))

    def repr(self: Self): String = "Matx(" + ", ".join(rows().map(row -> row.toList())) + ")"

    def toFloat32Array(self): Float32Array = data.toFloat32Array()
}
