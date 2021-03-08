package cjx.js.web

import cjx.js.web.Window
import www.JSWrapper
import www.JSObject

class WebGLVertexArrayObject : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLVertexArrayObject")
}
