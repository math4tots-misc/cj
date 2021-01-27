package cjx.mat

import cj.Float64Array
import cj.Math
import cjx.mat.Matrix

## Some utilities ported from github.com/toji/gl-matrix
class Mat4 {

    ## Generates a perspective projection matrix with the given bounds.
    ## The near/far clip planes correspond to a normalized device coordinate Z range of [-1, 1]
    ## which matches WebGL/OpenGL's clip volume.
    ##
    ## - fovy: Vertical field of view in radians
    ## - aspect: Aspect ratio. typically viewport width/height
    ## - near: Near bound of the frustum
    ## - far: Far bound of the frustum, can be infinity
    ##
    def perspective(fovy: Double, aspect: Double, near: Double, far: Double): Matrix = {
        val f = 1.0 / Math.tan(fovy / 2)
        val out = Float64Array(
            f / aspect, 0, 0, 0,
            0, f, 0, 0,
            0, 0, 0, -1,
            0, 0, 0, 0)
        if far != Math.infinity {
            val nf = 1.0 / (near - far)
            out[10] = (far + near) * nf
            out[14] = 2.0 * far * near * nf
        } else {
            out[10] = -1
            out[14] = -2.0 * near
        }
        Matrix._fromParts(4, out)
    }

    ## Translate a mat4 by the given vector
    def translate(a: Matrix, v: Tuple[Double, Double, Double]): Matrix = {
        val (x, y, z) = v
        val data = a.data
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

        val out = Float64Array(
            a00,
            a01,
            a02,
            a03,
            a10,
            a11,
            a12,
            a13,
            a20,
            a21,
            a22,
            a23,
            a00 * x + a10 * y + a20 * z + data[12],
            a01 * x + a11 * y + a21 * z + data[13],
            a02 * x + a12 * y + a22 * z + data[14],
            a03 * x + a13 * y + a23 * z + data[15])

        Matrix._fromParts(4, out)
    }
}
