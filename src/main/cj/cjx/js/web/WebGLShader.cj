package cjx.js.web

import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.JSWrapper

class WebGLShader : JSWrapper {
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("WebGLShader")
}
