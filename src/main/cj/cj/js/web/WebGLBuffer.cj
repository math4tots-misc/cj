package cj.js.web

import cj.js.web.Window
import cj.js.JSObject

class WebGLBuffer {
    val _obj :  JSObject
    def obj(self: Self): JSObject = self._obj
    def cls() : JSObject = Window.get().field("WebGLBuffer")
}
