package cjx.books.webgl.main

import cj.js.web.WebGLBuffer
import cj.js.web.WebGLVertexArrayObject
import cj.Int16Array
import cjx.books.webgl.main.Base


class Ch02s05 : Base {
    val base : Base.Data = Default()
    var indices : Int16Array = ?
    var coneVAO : WebGLVertexArrayObject = ?
    var vboName : String = ?
    var iboName : String = ?
    var codeIndexBuffer : WebGLBuffer = ?
    var vboSize : Int = 0
    var vboUsage : Int = 0
    var iboSize : Int = 0
    var iboUsage : Int = 0
    var isVerticesVbo : Bool = false
    var isConeVertexBufferVbo : Bool = false
    def main() = __malloc().run()

    def run(self: Self) = {
        document.title = "WebGL2 ch02s05"
        canvas.width = window.innerWidth
        canvas.height = window.innerHeight
        val gl = self.gl
        gl.clearColor(0, 0, 0, 1)
        self.initProgram()
        # aVertexPosition = gl.getAttribLocation(self.program, "aVertexPosition")
        # self.initBuffers()
        # self.render()
    }
}
