package cj.js.web

import cj.js.web.WebGL2RenderingContext
import cj.js.web.CanvasRenderingContext2D
import cj.js.web.Window
import cj.js.JSObject
import cj.js.web.HTMLElement

class HTMLCanvasElement : HTMLElement {
    val _obj :  JSObject
    def obj(self: Self): JSObject = self._obj
    def cls() : JSObject = Window.get().field("HTMLCanvasElement")

    def __get_width(self: Self): Int = self.field("width").unsafeCast()
    def __set_width(self: Self, value: Int) = self.setField("width", value)
    def __get_height(self: Self): Int = self.field("height").unsafeCast()
    def __set_height(self: Self, value: Int) = self.setField("height", value)

    def getContext2D(self: Self): CanvasRenderingContext2D = (
        self.call("getContext", "2d").unsafeCast())

    def getContextWebGL(self: Self): WebGL2RenderingContext = (
        self.call("getContext", "webgl2").unsafeCast())
}
