package cj.js.web

import cj.js.web.Window
import cj.js.JSWrapper
import cj.js.JSObject

class WebGLVertexArrayObject : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLVertexArrayObject")
}
