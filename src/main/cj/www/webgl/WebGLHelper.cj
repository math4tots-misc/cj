package www.webgl

import cj.Error
import www.dom.WebGLProgram
import www.dom.HTMLScriptElement
import www.dom.WebGLShader
import www.dom.Window
import www.dom.Document
import www.dom.WebGL2RenderingContext
import www.dom.HTMLCanvasElement

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
        val script : HTMLScriptElement = document.getElementById(id)
        val shaderString = script.text.trim()

        val type = if script.type == "x-shader/x-vertex" {
            gl.cVERTEX_SHADER
        } else {
            Assert.equal(script.type, "x-shader/x-fragment")
            gl.cFRAGMENT_SHADER
        }

        compileShader(type, shaderString)
    }

    private def compileShader(self, type: Int, shaderSource: String): WebGLShader {
        val shader = gl.createShader(type)
        gl.shaderSource(shader, shaderSource)
        gl.compileShader(shader)
        if not gl.spCOMPILE_STATUS(shader) {
            throw Error(gl.getShaderInfoLog(shader))
        }
        shader
    }

    def initProgram(self: Self) = {
        val vertexShader = self.getShader("vertex-shader")
        val fragmentShader = self.getShader("fragment-shader")

        initProgramWithCompiledShaders(vertexShader, fragmentShader)
    }

    def initProgramWithShaders(self, vertexShaderSource: String, fragmentShaderSource: String) {
        initProgramWithCompiledShaders(
            compileShader(gl.cVERTEX_SHADER, vertexShaderSource),
            compileShader(gl.cFRAGMENT_SHADER, fragmentShaderSource))
    }

    private def initProgramWithCompiledShaders(
            self, vertexShader: WebGLShader, fragmentShader: WebGLShader) {

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
