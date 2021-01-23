package cj.js.web

import cj.js.web.CanvasRenderingContext2D
import cj.js.web.Window
import cj.js.JSObject
import cj.js.web.HTMLElement

class HTMLCanvasElement : HTMLElement {
    val _obj :  JSObject
    def obj(self: Self): JSObject = self._obj
    def cls() : JSObject = Window.get().field("HTMLCanvasElement")

    def getContext2D(self: Self): CanvasRenderingContext2D = (
        self.call("getContext", "2d").unsafeCast())
}
