package cjx.js.web

import cjx.js.web.Window
import www.JSObject

class WebGLBuffer {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLBuffer")
}
