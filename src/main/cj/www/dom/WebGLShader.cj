package www.dom

import www.dom.Window
import www.JSObject
import www.JSWrapper

class WebGLShader : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLShader")
}
