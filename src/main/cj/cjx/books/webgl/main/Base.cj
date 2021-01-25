package cjx.books.webgl.main

import cj.js.web.WebGLProgram
import cj.js.web.WebGLShader
import cj.js.web.HTMLCanvasElement
import cj.js.web.Window
import cj.js.web.HTMLScriptElement
import cj.js.web.Document
import cj.js.web.WebGL2RenderingContext

trait Base {

    class Data : Default {
        val window : Window
        val document : Document
        val canvas : HTMLCanvasElement
        val gl : WebGL2RenderingContext
        @default var _program : Nullable[WebGLProgram]

        def default() : Self = {
            val window = Window.get()
            val document = Document.get()
            val canvas : HTMLCanvasElement = document.getElementBydId("canvas")
            val gl = canvas.getContextWebGL()
            gl.clearColor(0, 0, 0, 1)
            Self.__dmalloc(window, document, canvas, gl)
        }
    }

    def __get_base(self: Self): Data
    def __get_window(self: Self): Window = self.base.window
    def __get_document(self: Self): Document = self.base.document
    def __get_canvas(self: Self): HTMLCanvasElement = self.base.canvas
    def __get_gl(self: Self): WebGL2RenderingContext = self.base.gl
    def __get_program(self: Self): WebGLProgram = self.base._program.get()

    def getShader(self: Self, id: String) : WebGLShader = {
        val document = self.document
        val gl = self.gl

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
        val gl = self.gl
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
        self.base._program = null(program)
    }
}
