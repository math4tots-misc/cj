package cj.js.web

import cj.js.JSObject
import cj.js.web.Window

class WebGLUniformLocation {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLUniformLocation")
}
