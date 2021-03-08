package www.dom

import www.dom.CanvasRenderingContext
import www.dom.HTMLCanvasElement
import www.dom.Window
import www.JSObject
import www.JSWrapper

class CanvasRenderingContext2D : CanvasRenderingContext {
    def _getFromCanvas(canvas: HTMLCanvasElement): Self = canvas.getContext2D()

    val _obj :  JSObject
    def cls() : JSObject = Window.get().field("CanvasRenderingContext2D")

    def __get_canvas(self): HTMLCanvasElement? = self.field("canvas").unsafeCast()

    def __get_lineWidth(self: Self): Double = self.field("lineWidth").unsafeCast()
    def __set_lineWidth(self: Self, value: Double) = self.setField("lineWidth", value)

    def __get_fillStyle(self: Self): String = self.field("fillStyle").unsafeCast()
    def __set_fillStyle(self: Self, style: String) = self.setField("fillStyle", style)

    def fillRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        self.call("fillRect", x, y, width, height))

    def strokeRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        self.call("strokeRect", x, y, width, height))

    def clearRect(self: Self, x: Double, y: Double, width: Double, height: Double) = (
        self.call("clearRect", x, y, width, height))

    def beginPath(self: Self) = self.call("beginPath")
    def closePath(self: Self) = self.call("closePath")
    def stroke(self: Self) = self.call("stroke")
    def moveTo(self: Self, x: Double, y: Double) = self.call("moveTo", x, y)
    def lineTo(self: Self, x: Double, y: Double) = self.call("lineTo", x, y)
}
