package cj.js.web

import cj.js.web.Window
import cj.js.JSObject
import cj.js.JSWrapper

class CanvasRenderingContext2D : JSWrapper {
    val _obj :  JSObject
    def obj(self: Self): JSObject = self._obj
    def cls() : JSObject = Window.get().field("CanvasRenderingContext2D")

    def __get_lineWidth(self: Self): Double = self.field("lineWidth").unsafeCast()
    def __set_lineWidth(self: Self, value: Double) = self.setField("lineWidth", value)

    def __get_fillStyle(self: Self): String = self.field("fillStyle").unsafeCast()
    def __set_fillStyle(self: Self, style: String) = self.setField("fillStyle", style)

    def fillRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        self.call("fillRect", x, y, width, height))

    def strokeRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        self.call("strokeRect", x, y, width, height))

    def beginPath(self: Self) = self.call("beginPath")
    def closePath(self: Self) = self.call("closePath")
    def stroke(self: Self) = self.call("stroke")
    def moveTo(self: Self, x: Double, y: Double) = self.call("moveTo", x, y)
    def lineTo(self: Self, x: Double, y: Double) = self.call("lineTo", x, y)
}
