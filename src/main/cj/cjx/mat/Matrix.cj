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

    def __add(self: Self, other: Self): Self = {
        val c = c
        val data = data
        val otherData = other.data
        val len = data.size()
        if c != other.c or len != otherData.size() {
            throw Error("Invalid dimensions for Matrix.__add")
        }
        val out = Float64Array.withSize(len)
        for i = 0; i < len; i += 1 {
            out[i] = data[i] + otherData[i]
        }
        __malloc(c, out)
    }

    def rows(self: Self): List[List[Double]] = {
        val rs: List[List[Double]] = []
        for ri = 0; ri < r; ri += 1 {
            rs.add([])
            for ci = 0; ci < c; ci += 1 {
                rs.last().add(data[ri * c + ci])
            }
        }
        rs
    }

    def hash(self: Self): Int = (c, data).hash()

    def __eq(self: Self, other: Self): Bool = c == other.c and data == other.data

    def repr(self: Self): String = "Matrix(" + ", ".join(rows()) + ")"
}
