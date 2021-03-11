package www.dom

import www.JSObject

class WebGLBuffer {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "WebGLBuffer")
}
