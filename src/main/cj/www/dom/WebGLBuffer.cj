package www.dom

import www.dom.Window
import www.JSObject

class WebGLBuffer {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLBuffer")
}
