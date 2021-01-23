package cj.js.web

import cj.js.web.WebGLRenderingContext
import cj.js.JSWrapper
import cj.js.web.Window
import cj.js.JSObject

class WebGL2RenderingContext : WebGLRenderingContext {
    val _obj : JSObject
    def obj(self: Self): JSObject = self._obj
    def cls() : JSObject = Window.get().field("WebGL2RenderingContext")
}
