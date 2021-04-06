package www.dom

import www.dom.HTMLCanvasElement
import www.dom.WebGLVertexArrayObject
import www.dom.WebGLRenderingContext
import www.JSWrapper
import www.JSObject

class WebGL2RenderingContext : WebGLRenderingContext {
    def _getFromCanvas(canvas: HTMLCanvasElement): Self = canvas.getContextWebGL()

    val _obj : JSObject
    def cls() : JSObject = js!(JSObject, "WebGL2RenderingContext")

    # === constants ===
    # properties starting with 'c'

    # c*_BUFFER (See also WebGLRenderingContext.c*_BUFFER fields)
    def __get_cCOPY_READ_BUFFER(self: Self): Int = js0!(self, ".COPY_READ_BUFFER")
    def __get_cCOPY_WRITE_BUFFER(self: Self): Int = js0!(self, ".COPY_WRITE_BUFFER")
    def __get_cTRANSFORM_FEEDBACK_BUFFER(self: Self): Int = (
        js0!(self, ".TRANSFORM_FEEDBACK_BUFFER"))
    def __get_cUNIFORM_BUFFER(self: Self): Int = js0!(self, ".UNIFORM_BUFFER")
    def __get_cPIXEL_PACK_BUFFER(self: Self): Int = js0!(self, ".PIXEL_PACK_BUFFER")
    def __get_cPIXEL_UNPACK_BUFFER(self: Self): Int = (
        js0!(self, ".PIXEL_UNPACK_BUFFER"))

    # c*_READ and C*_COPY (See also WebGLRenderingContext.c*_DRAW fields)
    # for specifying buffer usage patterns
    def __get_cSTATIC_READ(self: Self): Int = js0!(self, ".STATIC_READ")
    def __get_cDYNAMIC_READ(self: Self): Int = js0!(self, ".DYNAMIC_READ")
    def __get_cSTREAM_READ(self: Self): Int = js0!(self, ".STREAM_READ")
    def __get_cSTATIC_COPY(self: Self): Int = js0!(self, ".STATIC_COPY")
    def __get_cDYNAMIC_COPY(self: Self): Int = js0!(self, ".DYNAMIC_COPY")
    def __get_cSTREAM_COPY(self: Self): Int = js0!(self, ".STREAM_COPY")

    # *VertexArray methods
    def createVertexArray(self: Self): WebGLVertexArrayObject = (
        self.call("createVertexArray").unsafeCast())

    def bindVertexArray(self: Self, vertexArray: WebGLVertexArrayObject) = (
        self.call("bindVertexArray", vertexArray))

    def unbindVertexArray(self: Self) = self.call("bindVertexArray", null[WebGLVertexArrayObject])

    def vertexAttribDivisor(self, index: Int, divisor: Int) = call(
        "vertexAttribDivisor", index, divisor)

    def drawArraysInstanced(self: Self, mode: Int, first: Int, count: Int, instanceCount: Int) = (
        self.call("drawArraysInstanced", mode, first, count, instanceCount))
}
