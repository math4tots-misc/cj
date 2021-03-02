package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.JSWrapper

## A "Program" is a combination of vertex and fragment shaders
class WebGLProgram : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLProgram")
}
