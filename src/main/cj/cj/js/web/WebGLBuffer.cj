package cj.js.web

import cj.js.web.Window
import cj.js.JSObject

class WebGLBuffer {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLBuffer")
}
