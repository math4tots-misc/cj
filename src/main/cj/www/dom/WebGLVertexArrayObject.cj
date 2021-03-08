package www.dom

import www.dom.Window
import www.JSWrapper
import www.JSObject

class WebGLVertexArrayObject : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLVertexArrayObject")
}
