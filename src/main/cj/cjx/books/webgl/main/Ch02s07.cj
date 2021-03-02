package cjx.books.webgl.main

import cj.Int16Array
import cj.Float32Array
import cjx.math.mat.Mat4
import cjx.js.web.WebGLUniformLocation
import cj.net.HTTP
import cj.JSON
import cjx.books.webgl.main.Base
import cjx.math.mat.Matx
import cjx.js.web.WebGLBuffer
import cjx.js.web.WebGLVertexArrayObject

## Load a cone with AJAX
class Ch02s07 : Base {
    val base : Base.Data = Default()
    var model : JSON = 0
    var coneVAO : WebGLVertexArrayObject = ?
    var modelIndexBuffer : WebGLBuffer = ?
    var projectionMatrix : Matx = Matx.identity(4)
    var modelViewMatrix : Matx = Matx.identity(4)
    var aVertexPosition : Int = 0
    var uProjectionMatrix : WebGLUniformLocation = ?
    var uModelViewMatrix : WebGLUniformLocation = ?
    var uModelColor : WebGLUniformLocation = ?
    var vertices : Float32Array = Default()
    var indices : Int16Array = Default()
    var color : Float32Array = Default()
    def main() = __malloc().run()

    def run(self) {
        document.title = "WebGL2 ch02s07"
        canvas.width = window.innerWidth
        canvas.height = window.innerHeight
        gl.clearColor(0, 0, 0, 1)
        initProgram()
        aVertexPosition = gl.getAttribLocation(program, "aVertexPosition")
        uProjectionMatrix = gl.getUniformLocation(program, "uProjectionMatrix").get()
        uModelViewMatrix = gl.getUniformLocation(program, "uModelViewMatrix").get()
        uModelColor = gl.getUniformLocation(program, "uModelColor").get()
        IO.println("before amain")
        amain().done()
    }

    async def amain(self) : Promise[Unit] {
        IO.println("Starting amain")
        aload("cone1.json").await
        IO.println("cone1.json loaded")
        render()
        IO.println("started render")
    }

    async def aload(self, path: String) : Promise[Unit] {
        model = JSON.parse(HTTP.get(path).await)
        vertices = model["vertices"].toFloat32Array()
        indices = model["indices"].toInt16Array()
        color = model["color"].toFloat32Array()
        IO.println("vertices = " + vertices)
        IO.println("indices = " + indices)
        IO.println("color = " + color)
        handleModel()
    }

    private def handleModel(self) {
        coneVAO = gl.createVertexArray()
        gl.bindVertexArray(coneVAO)
        gl.uniform3fv(uModelColor, color)
        val modelVertexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cARRAY_BUFFER, modelVertexBuffer)
        gl.bufferData(gl.cARRAY_BUFFER, vertices, gl.cSTATIC_DRAW)

        gl.enableVertexAttribArray(aVertexPosition)
        gl.vertexAttribPointer(aVertexPosition, 3, gl.cFLOAT, false, 0, 0)

        modelIndexBuffer = gl.createBuffer()
        gl.bindBuffer(gl.cELEMENT_ARRAY_BUFFER, modelIndexBuffer)
        gl.bufferData(gl.cELEMENT_ARRAY_BUFFER, indices, gl.cSTATIC_DRAW)

        gl.unbindVertexArray()
    }

    def draw(self) {
        gl.clear(gl.cCOLOR_BUFFER_BIT | gl.cDEPTH_BUFFER_BIT)
        gl.viewport(0, 0, canvas.width, canvas.height)

        projectionMatrix = Mat4.perspective(45, canvas.width / canvas.height, 0.1, 10000)
        modelViewMatrix = Mat4.translate(Matx.identity(4), (0, 0, -5.0))

        gl.uniformMatrix4fv(uProjectionMatrix, false, projectionMatrix.toFloat32Array())
        gl.uniformMatrix4fv(uModelViewMatrix, false, modelViewMatrix.toFloat32Array())

        gl.bindVertexArray(coneVAO)

        gl.drawElements(gl.cTRIANGLES, indices.size(), gl.cUNSIGNED_SHORT, 0)

        gl.unbindVertexArray()
    }
}
