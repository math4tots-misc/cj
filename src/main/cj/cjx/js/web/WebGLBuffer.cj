package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject

class WebGLBuffer {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLBuffer")
}
