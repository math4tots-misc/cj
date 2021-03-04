package cjx.js.web

import cjx.js.web.CanvasRenderingContext
import cjx.js.web.WebGL2RenderingContext
import cjx.js.web.CanvasRenderingContext2D
import cjx.js.web.Window
import cjx.js.JSObject
import cjx.js.web.HTMLElement

class HTMLCanvasElement : HTMLElement {
    static val tagName = "canvas"
    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("HTMLCanvasElement")

    def __get_width(self: Self): Int = self.field("width").unsafeCast()
    def __set_width(self: Self, value: Int) = self.setField("width", value)
    def __get_height(self: Self): Int = self.field("height").unsafeCast()
    def __set_height(self: Self, value: Int) = self.setField("height", value)

    def getContext[C: CanvasRenderingContext](self): C = C._getFromCanvas(self)

    def getContext2D(self: Self): CanvasRenderingContext2D = (
        self.call("getContext", "2d").unsafeCast())

    def getContextWebGL(self: Self): WebGL2RenderingContext = (
        self.call("getContext", "webgl2").unsafeCast())
}
