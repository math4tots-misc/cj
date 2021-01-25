package cj.js.web

import cj.js.web.Window
import cj.js.JSObject
import cj.js.JSWrapper

## A "Program" is a combination of vertex and fragment shaders
class WebGLProgram : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLProgram")
}
