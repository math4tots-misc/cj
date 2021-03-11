package www.dom

import www.JSObject
import www.JSWrapper

## A "Program" is a combination of vertex and fragment shaders
class WebGLProgram : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "WebGLProgram")
}
