package cj.js.web

import cj.Float32Array
import cj.js.JSWrapper

trait WebGLRenderingContext : JSWrapper {

    # === constants ===
    # properties starting with 'c'

    def __get_cDEPTH_BUFFER_BIT(self: Self): Int = self.field("DEPTH_BUFFER_BIT").unsafeCast()
    def __get_cSTENCIL_BUFFER_BIT(self: Self): Int = self.field("STENCIL_BUFFER_BIT").unsafeCast()
    def __get_cCOLOR_BUFFER_BIT(self: Self): Int = self.field("COLOR_BUFFER_BIT").unsafeCast()

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
}
