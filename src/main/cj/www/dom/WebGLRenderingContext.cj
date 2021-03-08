package www.dom

import www.dom.CanvasRenderingContext
import www.dom.WebGLUniformLocation
import www.dom.WebGLProgram
import www.dom.WebGLShader
import cj.ToArrayBufferView
import www.dom.WebGLBuffer
import cj.Float32Array
import www.JSWrapper

trait WebGLRenderingContext : CanvasRenderingContext {

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

    # c*_SHADER (type of shader)
    def __get_cVERTEX_SHADER(self: Self): Int = self.field("VERTEX_SHADER").unsafeCast()
    def __get_cFRAGMENT_SHADER(self: Self): Int = self.field("FRAGMENT_SHADER").unsafeCast()

    # Various getShaderParameter/getProgramParameter constants
    def __get_cDELETE_STATUS(self: Self): Int = self.field("DELETE_STATUS").unsafeCast()
    def __get_cCOMPILE_STATUS(self: Self): Int = self.field("COMPILE_STATUS").unsafeCast()
    def __get_cLINK_STATUS(self: Self): Int = self.field("LINK_STATUS").unsafeCast()
    def __get_cVALIDATE_STATUS(self: Self): Int = self.field("VALIDATE_STATUS").unsafeCast()
    def __get_cSHADER_TYPE(self: Self): Int = self.field("SHADER_TYPE").unsafeCast()
    def __get_cACTIVE_UNIFORMS(self: Self): Int = self.field("ACTIVE_UNIFORMS").unsafeCast()

    # getBufferParameter constants
    def __get_cBUFFER_SIZE(self: Self): Int = self.field("BUFFER_SIZE").unsafeCast()
    def __get_cBUFFER_USAGE(self: Self): Int = self.field("BUFFER_USAGE").unsafeCast()

    # Data type constants
    def __get_cBYTE(self: Self): Int = self.field("BYTE").unsafeCast()
    def __get_cSHORT(self: Self): Int = self.field("SHORT").unsafeCast()
    def __get_cUNSIGNED_BYTE(self: Self): Int = self.field("UNSIGNED_BYTE").unsafeCast()
    def __get_cUNSIGNED_SHORT(self: Self): Int = self.field("UNSIGNED_SHORT").unsafeCast()
    def __get_cFLOAT(self: Self): Int = self.field("FLOAT").unsafeCast()

    # Draw primitives
    def __get_cPOINTS(self: Self): Int = self.field("POINTS").unsafeCast()
    def __get_cLINE_STRIP(self: Self): Int = self.field("LINE_STRIP").unsafeCast()
    def __get_cLINE_LOOP(self: Self): Int = self.field("LINE_LOOP").unsafeCast()
    def __get_cLINES(self: Self): Int = self.field("LINES").unsafeCast()
    def __get_cTRIANGLE_STRIP(self: Self): Int = self.field("TRIANGLE_STRIP").unsafeCast()
    def __get_cTRIANGLE_FAN(self: Self): Int = self.field("TRIANGLE_FAN").unsafeCast()
    def __get_cTRIANGLES(self: Self): Int = self.field("TRIANGLES").unsafeCast()

    # --- constants for getParameter ---
    def __get_cCOLOR_CLEAR_VALUE(self: Self): Int = self.field("COLOR_CLEAR_VALUE").unsafeCast()
    def __get_cARRAY_BUFFER_BINDING(self: Self): Int = (
        self.field("ARRAY_BUFFER_BINDING").unsafeCast())
    def __get_cELEMENT_ARRAY_BUFFER_BINDING(self: Self): Int = (
        self.field("ELEMENT_ARRAY_BUFFER_BINDING").unsafeCast())

    # === params ===
    # properties starting with 'p'
    # wraps the 'getParameter' method
    def __get_pCOLOR_CLEAR_VALUE(self: Self): Float32Array = (
        self.call("getParameter", self.cCOLOR_CLEAR_VALUE).unsafeCast())
    def __get_pARRAY_BUFFER_BINDING(self): WebGLBuffer = (
        self.call("getParameter", self.cARRAY_BUFFER_BINDING).unsafeCast())
    def __get_pELEMENT_ARRAY_BUFFER_BINDING(self): WebGLBuffer = (
        self.call("getParameter", self.cELEMENT_ARRAY_BUFFER_BINDING).unsafeCast())

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
    # =================================== DRAWING ================================================
    # ============================================================================================

    ## Renders primitives from array data
    ## - mode: Type of primitive to render. (Possible values: POINTS, LINE_STRIP, TRIANGLES...)
    ## - count: Number of elements to be rendered
    ## - type: tyep of values in the element array buffer. (Possible values:
    ##     UNSIGNED_BYTE, UNSIGNED_SHORT)
    ## - offset: byte offset in the element array buffer. Must be a valid multiple of the size
    ##     of the given type.
    def drawElements(self: Self, mode: Int, count: Int, type: Int, offset: Int) = (
        self.call("drawElements", mode, count, type, offset))

    def drawArrays(self: Self, mode: Int, first: Int, count: Int) = (
        self.call("drawArrays", mode, first, count))

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

    def isBuffer(self, buffer: WebGLBuffer): Bool = call("isBuffer", buffer).unsafeCast()

    ## getBufferParameter(target, BUFFER_SIZE)
    def bpBUFFER_SIZE(self, target: Int): Int = (
        call("getBufferParameter", target, self.cBUFFER_SIZE).unsafeCast())

    ## getBufferParameter(target, BUFFER_USAGE)
    def bpBUFFER_USAGE(self, target: Int): Int = (
        call("getBufferParameter", target, self.cBUFFER_USAGE).unsafeCast())

    # ============================================================================================
    # =================================== SHADERS ================================================
    # ============================================================================================

    ## Creates and initializes a WebGLProgram object
    ## (A program is a combination of vertex and fragment shaders)
    def createProgram(self: Self): WebGLProgram = self.call("createProgram").unsafeCast()

    ## Attaches either a fragment or vertex shader to a program
    def attachShader(self: Self, program: WebGLProgram, shader: WebGLShader) = (
        self.call("attachShader", program, shader))

    ## links a given WebGLProgram, completing the process of preparing the GPU code for
    ## the program's fragment and vertex shaders
    def linkProgram(self: Self, program: WebGLProgram) = self.call("linkProgram", program)

    ## Creates a WebGLShader that can then be configured further using shaderSource() and
    ## compileShader().
    def createShader(self: Self, type: Int): WebGLShader = (
        self.call("createShader", type).unsafeCast())

    ## Sets the source code of a WebGLShader
    def shaderSource(self: Self, shader: WebGLShader, source: String) = (
        self.call("shaderSource", shader, source))

    ## Compiles a GLSL shader into binary data so that it can be used by a WebGLProgram
    def compileShader(self: Self, shader: WebGLShader) = self.call("compileShader", shader)

    def getShaderInfoLog(self: Self, shader: WebGLShader): String = (
        self.call("getShaderInfoLog", shader).unsafeCast())

    ## Sets the specified WebGLProgram as part of the current rendering state
    def useProgram(self: Self, program: WebGLProgram) = self.call("useProgram", program)

    ## Returns the location of an attribute variable in a given WebGLProgram
    ## Returns -1 if variable name is not found.
    def getAttribLocation(self: Self, program: WebGLProgram, name: String): Int = (
        self.call("getAttribLocation", program, name).unsafeCast())

    ## Binds the buffer currently bound to ARRAY_BUFFER to a generic vertex attribute
    ## of the current vertex buffer object and specifies its layout
    ## - index : the index of the vertex attribute that is to be modified
    ## - size : number of components per vertex attribute (1, 2, 3, or 4)
    ## - type : data type of each component in the array.
    ##     (possible values, BYTE, SHORT, UNSIGNED_BYTE, UNSIGNED_SHORT, FLOAT)
    def vertexAttribPointer(
            self: Self,
            index: Int,
            size: Int,
            type: Int,
            normalized: Bool,
            stride: Int,
            offset: Int) = (
        self.call("vertexAttribPointer", index, size, type, normalized, stride, offset))

    def enableVertexAttribArray(self: Self, index: Int) = (
        self.call("enableVertexAttribArray", index))

    def getUniformLocation(self, program: WebGLProgram, name: String): Nullable[WebGLUniformLocation] = (
        self.call("getUniformLocation", program, name).unsafeCast())

    def uniformMatrix2fv(self, location: WebGLUniformLocation, transpose: Bool, value: Float32Array) = (
        self.call("uniformMatrix2fv", location, transpose, value))

    def uniformMatrix3fv(self, location: WebGLUniformLocation, transpose: Bool, value: Float32Array) = (
        self.call("uniformMatrix3fv", location, transpose, value))

    def uniformMatrix4fv(self, location: WebGLUniformLocation, transpose: Bool, value: Float32Array) = (
        self.call("uniformMatrix4fv", location, transpose, value))

    def uniform1f(self, location: WebGLUniformLocation, data: Double) = (
        call("uniform1f", location, data))

    def uniform1fv(self, location: WebGLUniformLocation, data: Float32Array) = (
        call("uniform1fv", location, data))
    def uniform2fv(self, location: WebGLUniformLocation, data: Float32Array) = (
        call("uniform2fv", location, data))
    def uniform3fv(self, location: WebGLUniformLocation, data: Float32Array) = (
        call("uniform3fv", location, data))
    def uniform4fv(self, location: WebGLUniformLocation, data: Float32Array) = (
        call("uniform4fv", location, data))

    ## getShaderParameter(shader, DELETE_STATUS)
    def spDELETE_STATUS(self: Self, shader: WebGLShader): Bool = (
        self.call("getShaderParameter", shader, self.cDELETE_STATUS).unsafeCast())

    ## getShaderParameter(shader, COMPILE_STATUS)
    def spCOMPILE_STATUS(self: Self, shader: WebGLShader): Bool = (
        self.call("getShaderParameter", shader, self.cCOMPILE_STATUS).unsafeCast())

    ## getShaderParameter(shader, SHADER_TYPE)
    def spSHADER_TYPE(self: Self, shader: WebGLShader): Int = (
        self.call("getShaderParameter", shader, self.cSHADER_TYPE).unsafeCast())

    ## getProgramParameter(program, DELETE_STATUS)
    def ppDELETE_STATUS(self: Self, program: WebGLProgram): Bool = (
        self.call("getProgramParameter", program, self.cDELETE_STATUS).unsafeCast())

    ## getProgramParameter(program, LINK_STATUS)
    def ppLINK_STATUS(self: Self, program: WebGLProgram): Bool = (
        self.call("getProgramParameter", program, self.cLINK_STATUS).unsafeCast())

    ## getProgramParameter(program, VALIDATE_STATUS)
    def ppVALIDATE_STATUS(self: Self, program: WebGLProgram): Bool = (
        self.call("getProgramParameter", program, self.cVALIDATE_STATUS).unsafeCast())

    ## getProgramParameter(program, ACTIVE_UNIFORMS)
    def ppACTIVE_UNIFORMS(self: Self, program: WebGLProgram): Int = (
        self.call("getProgramParameter", program, self.cACTIVE_UNIFORMS).unsafeCast())
}
