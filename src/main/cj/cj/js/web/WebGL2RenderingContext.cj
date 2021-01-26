package cj.js.web

import cj.js.web.WebGLVertexArrayObject
import cj.js.web.WebGLRenderingContext
import cj.js.JSWrapper
import cj.js.web.Window
import cj.js.JSObject

class WebGL2RenderingContext : WebGLRenderingContext {
    val _obj : JSObject
    def cls() : JSObject = Window.get().field("WebGL2RenderingContext")

    # === constants ===
    # properties starting with 'c'

    # c*_BUFFER (See also WebGLRenderingContext.c*_BUFFER fields)
    def __get_cCOPY_READ_BUFFER(self: Self): Int = self.field("COPY_READ_BUFFER").unsafeCast()
    def __get_cCOPY_WRITE_BUFFER(self: Self): Int = self.field("COPY_WRITE_BUFFER").unsafeCast()
    def __get_cTRANSFORM_FEEDBACK_BUFFER(self: Self): Int = (
        self.field("TRANSFORM_FEEDBACK_BUFFER").unsafeCast())
    def __get_cUNIFORM_BUFFER(self: Self): Int = self.field("UNIFORM_BUFFER").unsafeCast()
    def __get_cPIXEL_PACK_BUFFER(self: Self): Int = self.field("PIXEL_PACK_BUFFER").unsafeCast()
    def __get_cPIXEL_UNPACK_BUFFER(self: Self): Int = (
        self.field("PIXEL_UNPACK_BUFFER").unsafeCast())

    # c*_READ and C*_COPY (See also WebGLRenderingContext.c*_DRAW fields)
    # for specifying buffer usage patterns
    def __get_cSTATIC_READ(self: Self): Int = self.field("STATIC_READ").unsafeCast()
    def __get_cDYNAMIC_READ(self: Self): Int = self.field("DYNAMIC_READ").unsafeCast()
    def __get_cSTREAM_READ(self: Self): Int = self.field("STREAM_READ").unsafeCast()
    def __get_cSTATIC_COPY(self: Self): Int = self.field("STATIC_COPY").unsafeCast()
    def __get_cDYNAMIC_COPY(self: Self): Int = self.field("DYNAMIC_COPY").unsafeCast()
    def __get_cSTREAM_COPY(self: Self): Int = self.field("STREAM_COPY").unsafeCast()

    # *VertexArray methods
    def createVertexArray(self: Self): WebGLVertexArrayObject = (
        self.call("createVertexArray").unsafeCast())

    def bindVertexArray(self: Self, vertexArray: WebGLVertexArrayObject) = (
        self.call("bindVertexArray", vertexArray))

    def unbindVertexArray(self: Self) = self.call("bindVertexArray", null[WebGLVertexArrayObject])
}
