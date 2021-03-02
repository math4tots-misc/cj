package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSWrapper
import cjx.js.JSObject

class WebGLVertexArrayObject : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLVertexArrayObject")
}
