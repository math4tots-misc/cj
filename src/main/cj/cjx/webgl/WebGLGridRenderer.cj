package cjx.webgl

import cjx.js.web.WebGLProgram
import cjx.js.web.WebGLUniformLocation
import cjx.js.web.WebGLVertexArrayObject
import cjx.js.web.WebGLBuffer
import cj.Float32Array
import cjx.js.web.WebGL2RenderingContext
import cjx.webgl.WebGLHelper
import cjx.js.web.HTMLCanvasElement
import cjx.js.web.Document
import cjx.js.web.Window

class WebGLGridRenderer {
    def __get_window(): Window = Window.get()
    def __get_document(): Document = Document.get()
    val canvas: HTMLCanvasElement
    val glh: WebGLHelper
    val gl: WebGL2RenderingContext
    val nrows: Int
    val ncols: Int
    val vertexData: Float32Array
    val vertexBuffer: WebGLBuffer
    val vao: WebGLVertexArrayObject
    val aVertexData: Int
    val uNRows: WebGLUniformLocation
    val uNCols: WebGLUniformLocation
    val program: WebGLProgram

    def(canvas: HTMLCanvasElement, nrows: Int, ncols: Int): Self {
        val glh = WebGLHelper(canvas)
        val gl = glh.gl
        val vertexData = Float32Array.withSize(nrows * ncols)

        glh.initProgramWithShaders(
            include_str!("shaders/grid.vert"),
            include_str!("shaders/grid.frag"))
        val program = glh.program
        val aVertexData = gl.getAttribLocation(program, "aVertexData")
        val uNRows = gl.getUniformLocation(program, "uNRows").get()
        val uNCols = gl.getUniformLocation(program, "uNCols").get()

        # init buffers
        val vao = gl.createVertexArray()
        gl.bindVertexArray(vao)
        val vertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, vertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertexData, gl.cSTREAM_DRAW)
        gl.vertexAttribPointer(aVertexData, 1, gl.cFLOAT, false, 0, 0)
        gl.vertexAttribDivisor(aVertexData, 1)
        gl.enableVertexAttribArray(aVertexData)
        gl.unbindVertexArray()
        gl.unbindBuffer(gl.cARRAY_BUFFER)

        __malloc(
            canvas,
            glh,
            gl,
            nrows,
            ncols,
            vertexData,
            vertexBuffer,
            vao,
            aVertexData,
            uNRows,
            uNCols,
            program)
    }

    def getPixel(self, r: Int, c: Int): Double = vertexData[r * ncols + c]

    def setPixel(self, r: Int, c: Int, value: Double) {
        vertexData[r * ncols + c] = value
    }

    def togglePixel(self, r: Int, c: Int) {
        setPixel(r, c, 1.0 - getPixel(r, c))
    }

    private def updateVertexBuffer(self) {
        IO.println("data = " + vertexData)
        gl.bindBuffer(gl.cARRAY_BUFFER, vertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertexData, gl.cSTREAM_DRAW)
        gl.unbindBuffer(gl.cARRAY_BUFFER)
    }

    def draw(self) {
        updateVertexBuffer()
        gl.clear(gl.cCOLOR_BUFFER_BIT | gl.cDEPTH_BUFFER_BIT)
        gl.viewport(0, 0, canvas.width, canvas.height)
        gl.bindVertexArray(vao)
        gl.uniform1f(uNRows, nrows)
        gl.uniform1f(uNCols, ncols)
        gl.drawArraysInstanced(gl.cTRIANGLE_FAN, 0, 4, vertexData.size())
        gl.unbindVertexArray()
    }
}
