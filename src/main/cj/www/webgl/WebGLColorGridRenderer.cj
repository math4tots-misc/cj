package www.webgl

import cjx.bmp.Color
import www.dom.WebGLProgram
import www.dom.WebGLUniformLocation
import www.dom.WebGLVertexArrayObject
import www.dom.WebGLBuffer
import cj.Float32Array
import www.dom.WebGL2RenderingContext
import www.webgl.WebGLHelper
import www.dom.HTMLCanvasElement
import www.dom.Document
import www.dom.Window

class WebGLColorGridRenderer {
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
    val aVertexColor: Int
    val uNRows: WebGLUniformLocation
    val uNCols: WebGLUniformLocation
    val program: WebGLProgram

    def(canvas: HTMLCanvasElement, nrows: Int, ncols: Int): Self {
        val glh = WebGLHelper(canvas)
        val gl = glh.gl
        val vertexData = Float32Array.withSize(nrows * ncols * 3)

        glh.initProgramWithShaders(
            include_str!("shaders/colorgrid.vert"),
            include_str!("shaders/colorgrid.frag"))
        val program = glh.program
        val aVertexColor = gl.getAttribLocation(program, "aVertexColor")
        val uNRows = gl.getUniformLocation(program, "uNRows").get()
        val uNCols = gl.getUniformLocation(program, "uNCols").get()

        # init buffers
        val vao = gl.createVertexArray()
        gl.bindVertexArray(vao)
        val vertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, vertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertexData, gl.cSTREAM_DRAW)
        gl.vertexAttribPointer(aVertexColor, 3, gl.cFLOAT, false, 0, 0)
        gl.vertexAttribDivisor(aVertexColor, 1)
        gl.enableVertexAttribArray(aVertexColor)
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
            aVertexColor,
            uNRows,
            uNCols,
            program)
    }

    def getPixel(self, row: Int, col: Int): Color {
        val offset = (row * ncols + col) * 3
        val r = vertexData[offset]
        val g = vertexData[offset + 1]
        val b = vertexData[offset + 2]
        (r, g, b)
    }

    def setPixel(self, row: Int, col: Int, color: Color) {
        val offset = (row * ncols + col) * 3
        vertexData[offset] = color.r
        vertexData[offset + 1] = color.g
        vertexData[offset + 2] = color.b
    }

    def setAllPixels(self, color: Color) {
        val r = color.r
        val g = color.g
        val b = color.b
        for i = 0; i < vertexData.size(); i += 3 {
            vertexData[i] = r
            vertexData[i + 1] = g
            vertexData[i + 2] = b
        }
    }

    private def updateVertexBuffer(self) {
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
        gl.drawArraysInstanced(gl.cTRIANGLE_FAN, 0, 4, vertexData.size() // 3)
        gl.unbindVertexArray()
    }
}
