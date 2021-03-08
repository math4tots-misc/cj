package www.dom

import www.JSObject
import www.dom.Window

class WebGLUniformLocation {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLUniformLocation")
}
