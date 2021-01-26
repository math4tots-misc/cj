package cjx.books.webgl.main

import cj.Float32Array
import cj.Int16Array
import cj.js.web.WebGLBuffer
import cj.js.web.WebGLVertexArrayObject
import cjx.books.webgl.main.Base

@derive(default)
class Ch02s04 : Base {

    static val options : List[String] = [
        "TRIANGLES",
        "LINES",
        "POINTS",
        "LINE_LOOP",
        "LINE_STRIP",
        "TRIANGLE_STRIP",
        "TRIANGLE_FAN",
    ]

    val base : Base.Data
    var renderingMode : String
    @lateinit var indices: Int16Array
    @lateinit var trapezoidVAO: WebGLVertexArrayObject
    @lateinit var trapezoidIndexBuffer: WebGLBuffer
    @lateinit var aVertexPosition :Int
    def main() = Self.default().run()

    def run(self: Self) = {
        document.title = "WebGL2 ch02s04"
        canvas.width = window.innerWidth
        canvas.height = window.innerHeight
        renderingMode = "TRIANGLES"
        val gl = self.gl
        gl.clearColor(0, 0, 0, 1)
        self.initProgram()
        aVertexPosition = gl.getAttribLocation(self.program, "aVertexPosition")
        self.initBuffers()
        self.render()
        self.initControls()
    }

    def initBuffers(self: Self) = {
        val vertices = Float32Array(
            -0.5, -0.5, 0,
            -0.25, 0.5, 0,
            0.0, -0.5, 0,
            0.25, 0.5, 0,
            0.5, -0.5, 0
        )
        indices = Int16Array(0, 1, 2, 0, 2, 3, 2, 3, 4)

        trapezoidVAO = gl.createVertexArray()
        gl.bindVertexArray(trapezoidVAO)

        val trapezoidVertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, trapezoidVertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertices, gl.cSTATIC_DRAW)
        gl.vertexAttribPointer(aVertexPosition, 3, gl.cFLOAT, false, 0, 0)
        gl.enableVertexAttribArray(aVertexPosition)

        trapezoidIndexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cELEMENT_ARRAY_BUFFER, trapezoidIndexBuffer)
        gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)

        gl.unbindVertexArray()
        gl.unbindBuffer(gl.cARRAY_BUFFER)
        gl.unbindBuffer(gl.cELEMENT_ARRAY_BUFFER)
    }

    def draw(self: Self) = {
        gl.clear(gl.cCOLOR_BUFFER_BIT | gl.cDEPTH_BUFFER_BIT)
        gl.viewport(0, 0, canvas.width, canvas.height)

        gl.bindVertexArray(trapezoidVAO)

        switch (renderingMode) {
            case "TRIANGLES" = {
                indices = Int16Array(0, 1, 2, 2, 3, 4)
                gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)
                gl.drawElements(gl.cTRIANGLES, indices.size(), gl.cUNSIGNED_SHORT, 0)
            }
            case "LINES" = {
                indices = Int16Array(1, 3, 0, 4, 1, 2, 2, 3)
                gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)
                gl.drawElements(gl.cLINES, indices.size(), gl.cUNSIGNED_SHORT, 0)
            }
            case "POINTS" = {
                indices = Int16Array(1, 2, 3)
                gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)
                gl.drawElements(gl.cPOINTS, indices.size(), gl.cUNSIGNED_SHORT, 0)
            }
            case "LINE_LOOP" = {
                indices = Int16Array(2, 3, 4, 1, 0)
                gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)
                gl.drawElements(gl.cLINE_LOOP, indices.size(), gl.cUNSIGNED_SHORT, 0)
            }
            case "LINE_STRIP" = {
                indices = Int16Array(2, 3, 4, 1, 0)
                gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)
                gl.drawElements(gl.cLINE_STRIP, indices.size(), gl.cUNSIGNED_SHORT, 0)
            }
            case "TRIANGLE_STRIP" = {
                indices = Int16Array(0, 1, 2, 3, 4)
                gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)
                gl.drawElements(gl.cTRIANGLE_STRIP, indices.size(), gl.cUNSIGNED_SHORT, 0)
            }
            case "TRIANGLE_FAN" = {
                indices = Int16Array(0, 1, 2, 3, 4)
                gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)
                gl.drawElements(gl.cTRIANGLE_FAN, indices.size(), gl.cUNSIGNED_SHORT, 0)
            }
            else = {
                IO.eprintln("renderingMode? = " + renderingMode)
            }
        }

        gl.unbindVertexArray()
    }

    def render(self: Self) = {
        window.requestAnimationFrame(ts -> self.render())
        self.draw()
    }

    def initControls(self: Self) = {
        window.onkeydown(event -> {
            switch event.key {
                case "1"
                case "2"
                case "3"
                case "4"
                case "5"
                case "6"
                case "7" = {
                    renderingMode = options[event.key.parseInt().get() - 1]
                }
            }
        })
    }
}
