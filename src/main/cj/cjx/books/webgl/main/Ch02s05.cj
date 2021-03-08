package cjx.books.webgl.main

import www.dom.HTMLElement
import www.dom.WebGLUniformLocation
import cjx.math.mat.Mat4
import cj.Float32Array
import cjx.math.mat.Matx
import www.dom.WebGLBuffer
import www.dom.WebGLVertexArrayObject
import cj.Int16Array
import cjx.books.webgl.main.Base


class Ch02s05 : Base {
    val base : Base.Data = Default()
    var indices : Int16Array = ?
    var coneVAO : WebGLVertexArrayObject = ?
    var vboName : String = ?
    var iboName : String = ?
    var coneIndexBuffer : WebGLBuffer = ?
    var vboSize = 0
    var vboUsage = 0
    var iboSize = 0
    var iboUsage = 0
    var isVerticesVbo = false
    var isConeVertexBufferVbo = false
    var projectionMatrix : Matx = Matx.identity(4)
    var modelViewMatrix : Matx = Matx.identity(4)
    var uProjectionMatrix : WebGLUniformLocation = ?
    var uModelViewMatrix : WebGLUniformLocation = ?
    var aVertexPosition = 0
    def main() = __malloc().run()

    def run(self) {
        document.title = "WebGL2 ch02s05"
        canvas.width = window.innerWidth
        canvas.height = window.innerHeight
        val gl = self.gl
        gl.clearColor(0, 0, 0, 1)
        initProgram()
        aVertexPosition = gl.getAttribLocation(program, "aVertexPosition")
        uProjectionMatrix = gl.getUniformLocation(program, "uProjectionMatrix").get()
        uModelViewMatrix = gl.getUniformLocation(program, "uModelViewMatrix").get()
        initBuffers()
        render()

        updateInfo()
    }

    def initBuffers(self) {
        val vertices = Float32Array(
            1.5, 0, 0,
            -1.5, 1, 0,
            -1.5, 0.809017, 0.587785,
            -1.5, 0.309017, 0.951057,
            -1.5, -0.309017, 0.951057,
            -1.5, -0.809017, 0.587785,
            -1.5, -1, 0,
            -1.5, -0.809017, -0.587785,
            -1.5, -0.309017, -0.951057,
            -1.5, 0.309017, -0.951057,
            -1.5, 0.809017, -0.587785
        )
        indices = Int16Array(
            0, 1, 2,
            0, 2, 3,
            0, 3, 4,
            0, 4, 5,
            0, 5, 6,
            0, 6, 7,
            0, 7, 8,
            0, 8, 9,
            0, 9, 10,
            0, 10, 1
        )
        coneVAO = gl.createVertexArray()
        gl.bindVertexArray(coneVAO)

        val coneVertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, coneVertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertices, gl.cSTATIC_DRAW)
        gl.vertexAttribPointer(aVertexPosition, 3, gl.cFLOAT, false, 0, 0)
        gl.enableVertexAttribArray(aVertexPosition)

        coneIndexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cELEMENT_ARRAY_BUFFER, coneIndexBuffer)
        gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)

        if coneVertexBuffer is gl.pARRAY_BUFFER_BINDING {
            vboName = "coneVertexBuffer"
        }
        if coneIndexBuffer is gl.pELEMENT_ARRAY_BUFFER_BINDING {
            iboName = "coneIndexBuffer"
        }

        vboSize = gl.bpBUFFER_SIZE(gl.cARRAY_BUFFER)
        vboUsage = gl.bpBUFFER_USAGE(gl.cARRAY_BUFFER)

        iboSize = gl.bpBUFFER_SIZE(gl.cELEMENT_ARRAY_BUFFER)
        iboUsage = gl.bpBUFFER_USAGE(gl.cELEMENT_ARRAY_BUFFER)

        isConeVertexBufferVbo = gl.isBuffer(coneVertexBuffer)

        gl.unbindVertexArray()
        gl.unbindBuffer(gl.cARRAY_BUFFER)
        gl.unbindBuffer(gl.cELEMENT_ARRAY_BUFFER)
    }

    def draw(self) {
        gl.clear(gl.cCOLOR_BUFFER_BIT | gl.cDEPTH_BUFFER_BIT)
        gl.viewport(0, 0, canvas.width, canvas.height)

        projectionMatrix = Mat4.perspective(45, canvas.width / canvas.height, 0.1, 10000)
        modelViewMatrix = Mat4.translate(Matx.identity(4), (0, 0, -5))

        gl.uniformMatrix4fv(uProjectionMatrix, false, projectionMatrix.toFloat32Array())
        gl.uniformMatrix4fv(uModelViewMatrix, false, modelViewMatrix.toFloat32Array())

        gl.bindVertexArray(coneVAO)
        gl.drawElements(gl.cLINE_LOOP, indices.size(), gl.cUNSIGNED_SHORT, 0)
        gl.unbindVertexArray()
    }

    def updateInfo(self) {
        {
            val e : HTMLElement = document.getElementBydId("t-vbo-name")
            e.innerText = vboName
        }
        {
            val e : HTMLElement = document.getElementBydId("t-ibo-name")
            e.innerText = iboName
        }
        {
            val e : HTMLElement = document.getElementBydId("t-vbo-size")
            e.innerText = "" + vboSize
        }
        {
            val e : HTMLElement = document.getElementBydId("t-vbo-usage")
            e.innerText = "" + vboUsage
        }
        {
            val e : HTMLElement = document.getElementBydId("t-ibo-size")
            e.innerText = "" + iboSize
        }
        {
            val e : HTMLElement = document.getElementBydId("t-ibo-usage")
            e.innerText = "" + iboUsage
        }
        {
            val e : HTMLElement = document.getElementBydId("s-is-cone-vertex-buffer-vbo")
            e.innerText = if isConeVertexBufferVbo { "Yes" } else { "No" }
        }
    }
}
