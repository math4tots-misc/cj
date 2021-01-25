package cjx.books.webgl.main

import cj.Int16Array
import cj.Float32Array
import cj.js.web.HTMLCanvasElement
import cj.js.web.WebGL2RenderingContext
import cj.js.web.Document
import cj.js.web.Window

class Ch02s01 {
    def main() = {
        val window = Window.get()
        val document = Document.get()
        document.title = "WebGL2 ch02s01 demo"
        val canvas : HTMLCanvasElement = document.getElementBydId("canvas")
        val gl = canvas.getContextWebGL()
        val vertices = Float32Array(
            -0.5, 0.5, 0,
            -0.5, -0.5, 0,
            0.5, -0.5, 0,
            0.5, 0.5, 0,
        )
        val indices = Int16Array(0, 1, 2, 0, 2, 3)

        # setting up the VBO
        val squareVertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, squareVertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertices, gl.cSTATIC_DRAW)

        # setting up the IBO
        val squareIndexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cELEMENT_ARRAY_BUFFER, squareIndexBuffer)
        gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)

        # clean
        gl.unbindBuffer(gl.cARRAY_BUFFER)
        gl.unbindBuffer(gl.cELEMENT_ARRAY_BUFFER)
    }
}
