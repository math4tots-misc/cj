package cjx.books.webgl.main

import cj.js.web.WebGLBuffer
import cjx.books.webgl.main.Base
import cj.Int16Array
import cj.Float32Array
import cj.js.web.HTMLCanvasElement
import cj.js.web.WebGL2RenderingContext
import cj.js.web.Document
import cj.js.web.Window

@derive(default)
class Ch02s01 : Base {
    val base : Base.Data
    @unwrap var _squareVertexBuffer : Nullable[WebGLBuffer]
    @unwrap var _squareIndexBuffer : Nullable[WebGLBuffer]
    @unwrap var _vertices : Nullable[Float32Array]
    @unwrap var _indices : Nullable[Int16Array]
    @unwrap var _aVertexPosition : Nullable[Int]
    def new() : Self = Self.default()
    def main() = Self().run()

    def run(self: Self) = {
        self.document.title = "WebGL2 ch02s01 demo"
        self.canvas.width = self.window.innerWidth
        self.canvas.height = self.window.innerHeight

        val gl = self.gl
        gl.clearColor(0, 0, 0, 1)

        self.initProgram()
        self.aVertexPosition = gl.getAttribLocation(self.program, "aVertexPosition")
        self.initBuffers()
        self.draw()
    }

    def initBuffers(self: Self) = {
        val gl = self.gl
        val vertices = Float32Array(
            -0.5, 0.5, 0,
            -0.5, -0.5, 0,
            0.5, -0.5, 0,
            0.5, 0.5, 0,
        )
        val indices = Int16Array(0, 1, 2, 0, 2, 3)
        self.vertices = vertices
        self.indices = indices

        # setting up the VBO
        val squareVertexBuffer = gl.createBuffer()
        self.squareVertexBuffer = squareVertexBuffer
        gl.bindBuffer(gl.cARRAY_BUFFER, squareVertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertices, gl.cSTATIC_DRAW)

        # setting up the IBO
        val squareIndexBuffer = gl.createBuffer()
        self.squareIndexBuffer = squareIndexBuffer
        gl.bindBuffer(gl.cELEMENT_ARRAY_BUFFER, squareIndexBuffer)
        gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)

        # clean
        gl.unbindBuffer(gl.cARRAY_BUFFER)
        gl.unbindBuffer(gl.cELEMENT_ARRAY_BUFFER)
    }

    def draw(self: Self) = {
        val gl = self.gl

        # clear the scene
        gl.clear(gl.cCOLOR_BUFFER_BIT | gl.cDEPTH_BUFFER_BIT)
        gl.viewport(0, 0, self.canvas.width, self.canvas.height)

        # use the buffers we've constructed
        gl.bindBuffer(gl.cARRAY_BUFFER, self.squareVertexBuffer)
        gl.vertexAttribPointer(self.aVertexPosition, 3, gl.cFLOAT, false, 0, 0)
        gl.enableVertexAttribArray(self.aVertexPosition)

        # Bind IBO
        gl.bindBuffer(gl.cELEMENT_ARRAY_BUFFER, self.squareIndexBuffer)

        # Draw to the scene using trianble primitives
        gl.drawElements(gl.cTRIANGLES, self.indices.size(), gl.cUNSIGNED_SHORT, 0)

        # clean
        gl.unbindBuffer(gl.cARRAY_BUFFER)
        gl.unbindBuffer(gl.cELEMENT_ARRAY_BUFFER)
    }
}
