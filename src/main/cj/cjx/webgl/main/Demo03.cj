package cjx.webgl.main

import cjx.js.web.Window
import cjx.js.web.WebGLUniformLocation
import cjx.js.web.WebGLProgram
import cjx.js.web.WebGLVertexArrayObject
import cj.Float32Array
import cjx.js.web.WebGLBuffer
import cjx.js.web.WebGL2RenderingContext
import cjx.js.web.Document
import cjx.js.web.HTMLCanvasElement
import cjx.webgl.WebGLHelper

class Demo03 {
    static var modulo = 5
    static var remainder = 0
    static val nrows = 45
    static val ncols = 60
    static val window: Window = Window.get()
    static val document: Document = Document.get()
    static val canvas: HTMLCanvasElement = document.getElementBydId("canvas")
    static val glh: WebGLHelper = WebGLHelper(canvas)
    static val gl: WebGL2RenderingContext = glh.gl
    static val vertexData: Float32Array = Float32Array.withSize(nrows * ncols)
    static var vertexBuffer: WebGLBuffer = ?
    static var vao: WebGLVertexArrayObject = ?
    static var aVertexData: Int = ?
    static var uNRows: WebGLUniformLocation = ?
    static var uNCols: WebGLUniformLocation = ?
    def __get_program(): WebGLProgram = glh.program

    def main() {
        # Don't make initial state pitch black -- set all colors to be grey
        for i = 0; i < vertexData.size(); i++ {
            vertexData[i] = 0.2
        }

        glh.initProgram()
        aVertexData = gl.getAttribLocation(program, "aVertexData")
        IO.println("Active uniforms = " + gl.ppACTIVE_UNIFORMS(program))
        uNRows = gl.getUniformLocation(program, "uNRows").get()
        uNCols = gl.getUniformLocation(program, "uNCols").get()
        initBuffers()
        togglePixelGroup(3, 0)
        updateVertexBuffer()
        draw()

        var lastRem1 = 0
        var lastRem2 = modulo // 2 + 3
        var lastTimeStampMs = 0.0

        var tick: Fn[Double, Unit] = tsMs -> ()
        tick = tsMs -> {
            val elapsed = (tsMs - lastTimeStampMs) / 1000
            if elapsed > 0.5 {
                lastTimeStampMs = tsMs
                IO.println("elapsed = " + elapsed)

                togglePixelGroup(modulo, remainder % modulo)
                if modulo < 11 {
                    modulo++
                }
                remainder = (remainder + 1) % modulo
                updateVertexBuffer()
                draw()
            }
            window.requestAnimationFrame(tsMs -> tick.call(tsMs))
        }
        tick.call(0)
    }

    def getPixel(r: Int, c: Int): Double = vertexData[r * ncols + c]

    def setPixel(r: Int, c: Int, value: Double) {
        vertexData[r * ncols + c] = value
    }

    def togglePixel(r: Int, c: Int) {
        setPixel(r, c, 1.0 - getPixel(r, c))
    }

    def togglePixelGroup(m: Int, i: Int) {
        for r = 0; r < nrows; r++ {
            for c = 0; c < ncols; c++ {
                if (r + c) % m == i {
                    togglePixel(r, c)
                }
            }
        }
    }

    def updateVertexBuffer() {
        gl.bindBuffer(gl.cARRAY_BUFFER, vertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertexData, gl.cSTREAM_DRAW)
        gl.unbindBuffer(gl.cARRAY_BUFFER)
    }

    def initBuffers() {
        vao = gl.createVertexArray()
        gl.bindVertexArray(vao)

        vertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, vertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertexData, gl.cSTREAM_DRAW)
        gl.vertexAttribPointer(aVertexData, 1, gl.cFLOAT, false, 0, 0)
        gl.vertexAttribDivisor(aVertexData, 1)
        gl.enableVertexAttribArray(aVertexData)

        gl.unbindVertexArray()
        gl.unbindBuffer(gl.cARRAY_BUFFER)
    }

    def draw() {
        gl.clear(gl.cCOLOR_BUFFER_BIT | gl.cDEPTH_BUFFER_BIT)
        gl.viewport(0, 0, canvas.width, canvas.height)
        gl.bindVertexArray(vao)
        gl.uniform1f(uNRows, nrows)
        gl.uniform1f(uNCols, ncols)
        gl.drawArraysInstanced(gl.cTRIANGLE_FAN, 0, 4, vertexData.size())
        gl.unbindVertexArray()
    }
}
