package cjx.js.web

import cjx.js.JSObject
import cjx.js.web.Window

class WebGLUniformLocation {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLUniformLocation")
}
