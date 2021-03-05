package cjx.webgl.main

import cjx.js.web.WebGLProgram
import cjx.js.web.WebGLVertexArrayObject
import cj.Float32Array
import cjx.js.web.WebGLBuffer
import cjx.js.web.WebGL2RenderingContext
import cjx.js.web.Document
import cjx.js.web.HTMLCanvasElement
import cjx.webgl.WebGLHelper

class Demo01 {
    static val document: Document = Document.get()
    static val canvas: HTMLCanvasElement = document.getElementBydId("canvas")
    static val glh: WebGLHelper = WebGLHelper(canvas)
    static val gl: WebGL2RenderingContext = glh.gl
    static val vertexData: Float32Array = Float32Array(
        0,     0,  0,
        0.5,   0,  0,
        0.5, 0.5,  0,
    )
    static var vertexBuffer: WebGLBuffer = ?
    static var vao: WebGLVertexArrayObject = ?
    static var aVertexPosition: Int = ?
    def __get_program(): WebGLProgram = glh.program

    def main() {
        glh.initProgram()
        aVertexPosition = gl.getAttribLocation(program, "aVertexPosition")
        initBuffers()
        draw()
    }

    def initBuffers() {
        vao = gl.createVertexArray()
        gl.bindVertexArray(vao)

        vertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, vertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertexData, gl.cSTREAM_DRAW)
        gl.vertexAttribPointer(aVertexPosition, 3, gl.cFLOAT, false, 0, 0)
        gl.enableVertexAttribArray(aVertexPosition)

        gl.unbindVertexArray()
        gl.unbindBuffer(gl.cARRAY_BUFFER)
    }

    def draw() {
        gl.clear(gl.cCOLOR_BUFFER_BIT | gl.cDEPTH_BUFFER_BIT)
        gl.viewport(0, 0, canvas.width, canvas.height)
        gl.bindVertexArray(vao)
        gl.drawArrays(gl.cTRIANGLES, 0, vertexData.size() // 3)
        gl.unbindVertexArray()
    }
}
