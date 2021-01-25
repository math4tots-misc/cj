package cj.js.web

import cj.ToArrayBufferView
import cj.js.web.WebGLBuffer
import cj.Float32Array
import cj.js.JSWrapper

trait WebGLRenderingContext : JSWrapper {

    # === constants ===
    # properties starting with 'c'

    # c*_BUFFER_BIT
    def __get_cDEPTH_BUFFER_BIT(self: Self): Int = self.field("DEPTH_BUFFER_BIT").unsafeCast()
    def __get_cSTENCIL_BUFFER_BIT(self: Self): Int = self.field("STENCIL_BUFFER_BIT").unsafeCast()
    def __get_cCOLOR_BUFFER_BIT(self: Self): Int = self.field("COLOR_BUFFER_BIT").unsafeCast()

    # c*_BUFFER
    def __get_cARRAY_BUFFER(self: Self): Int = self.field("ARRAY_BUFFER").unsafeCast()
    def __get_cELEMENT_ARRAY_BUFFER(self: Self): Int = (
        self.field("ELEMENT_ARRAY_BUFFER").unsafeCast())

    # c*_DRAW (buffer usage constants)
    # for specifying buffer usage patterns
    def __get_cSTATIC_DRAW(self: Self): Int = self.field("STATIC_DRAW").unsafeCast()
    def __get_cDYNAMIC_DRAW(self: Self): Int = self.field("DYNAMIC_DRAW").unsafeCast()
    def __get_cSTREAM_DRAW(self: Self): Int = self.field("STREAM_DRAW").unsafeCast()

    # --- constants for getParameter ---
    def __get_cCOLOR_CLEAR_VALUE(self: Self): Int = self.field("COLOR_CLEAR_VALUE").unsafeCast()

    # === params ===
    # properties starting with 'p'
    # wraps the 'getParameter' method
    def __get_pCOLOR_CLEAR_VALUE(self: Self): Float32Array = (
        self.call("getParameter", self.cCOLOR_CLEAR_VALUE).unsafeCast())

    ## Sets the viewport, which specifies the affine transformation of x and y from normalized
    ## device coordinates to window coordinates.
    ## - x: specifies the horizontal coordinate for the lower left corner of the viewport origin
    ## - y: specifies the vertical coordinate for the lower left corner of the viewport origin
    ## - width: specifies the width fo the viewport
    ## - height: specifies the height of the viewport
    def viewport(self: Self, x: Int, y: Int, width: Int, height: Int) = (
        self.call("viewport", x, y, width, height))

    def clearColor(self: Self, red: Double, green: Double, blue: Double, alpha: Double) = (
        self.call("clearColor", red, green, blue, alpha))

    ## Clears buffers to preset values.
    ## - mask: bitwise OR mask that indicates the buffers to be cleared.
    ##    Possible values are:
    ##      gl.cCOLOR_BUFFER_BIT
    ##      gl.cCDEPTH_BUFFER_BIT
    ##      gl.cSTENCIL_BUFFER_BIT
    def clear(self: Self, mask: Int) = self.call("clear", mask)

    # ============================================================================================
    # =================================== BUFFERS ================================================
    # ============================================================================================
    def createBuffer(self: Self): WebGLBuffer = self.call("createBuffer").unsafeCast()

    def deleteBuffer(self: Self, buffer: WebGLBuffer) = self.call("deleteBuffer", buffer)

    def bindBuffer(self: Self, target: Int, buffer: WebGLBuffer) = (
        self.call("bindBuffer", target, buffer))

    def unbindBuffer(self: Self, target: Int) = self.call("bindBuffer", target, null[WebGLBuffer])

    ## Initializes and creates the buffer object's data store.
    def bufferData[D: ToArrayBufferView](self: Self, target: Int, srcData: D, usage: Int) = (
        self.call("bufferData", target, srcData.toArrayBufferView(), usage))
}
