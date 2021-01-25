package cj.js.web

import cj.js.web.Window
import cj.js.JSObject
import cj.js.JSWrapper

class WebGLShader : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLShader")
}
