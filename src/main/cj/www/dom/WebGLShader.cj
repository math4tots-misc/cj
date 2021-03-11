package www.dom

import www.JSObject
import www.JSWrapper

class WebGLShader : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = js!(JSObject, "WebGLShader")
}
