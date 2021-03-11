package www.dom

import www.JSWrapper
import www.JSObject

class WebGLVertexArrayObject : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "WebGLVertexArrayObject")
}
