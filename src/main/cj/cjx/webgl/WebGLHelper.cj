package cjx.webgl

import cjx.js.web.WebGLProgram
import cjx.js.web.HTMLScriptElement
import cjx.js.web.WebGLShader
import cjx.js.web.Window
import cjx.js.web.Document
import cjx.js.web.WebGL2RenderingContext
import cjx.js.web.HTMLCanvasElement

class WebGLHelper {
    private def __get_document(): Document = Document.get()
    private def __get_window(): Window = Window.get()

    val canvas: HTMLCanvasElement
    val gl: WebGL2RenderingContext
    var _program: WebGLProgram? = null
    def __get_program(self): WebGLProgram = _program.get()

    def(canvas: HTMLCanvasElement): Self {
        val gl: WebGL2RenderingContext = canvas.getContext()
        __malloc(canvas, gl)
    }

    def getShader(self: Self, id: String) : WebGLShader = {
        val script : HTMLScriptElement = document.getElementBydId(id)
        val shaderString = script.text.trim()

        val shader = if script.type == "x-shader/x-vertex" {
            gl.createShader(gl.cVERTEX_SHADER)
        } else {
            Assert.equal(script.type, "x-shader/x-fragment")
            gl.createShader(gl.cFRAGMENT_SHADER)
        }

        # Compile the shader using the supplied shader code
        gl.shaderSource(shader, shaderString)
        gl.compileShader(shader)

        # Ensure the shader is valid
        if not gl.spCOMPILE_STATUS(shader) {
            throw gl.getShaderInfoLog(shader)
        }

        shader
    }

    def initProgram(self: Self) = {
        val vertexShader = self.getShader("vertex-shader")
        val fragmentShader = self.getShader("fragment-shader")

        # Create a program
        val program = gl.createProgram()
        # Attach the shaders to this program
        gl.attachShader(program, vertexShader)
        gl.attachShader(program, fragmentShader)
        gl.linkProgram(program)

        if not gl.ppLINK_STATUS(program) {
            throw "Could not initialize shaders"
        }

        gl.useProgram(program)
        _program = null(program)
    }
}
